#' Repair Mojibake and Normalize Text to ASCII
#'
#' Repairs character strings that were corrupted by one or more rounds of
#' incorrect Latin-1-as-UTF-8 decoding (a recurring artifact in RSF's source
#' files), then transliterates any remaining accented characters to their
#' closest ASCII equivalent. Detection and repair are byte-level and
#' generic, so this handles corruption depth (single or double mojibake) and
#' new corrupted values automatically, without needing a hand-maintained
#' list of known-bad strings.
#'
#' @param x Character vector, potentially containing mojibake and/or
#'   accented characters
#' @param max_passes Maximum number of mojibake-repair passes to attempt
#'   (guards against pathological input; real-world cases resolve in 1-2
#'   passes)
#'
#' @return Character vector, ASCII-only
#' @keywords internal
repair_and_asciify <- function(x, max_passes = 3) {
  # A "\u00c3" or "\u00c2" character immediately followed by a Latin-1
  # continuation-range character is the telltale sign of UTF-8 bytes that
  # were decoded as Latin-1
  looks_mojibake <- function(s) {
    !is.na(s) & grepl("[\u00c2\u00c3][\u0080-\u00bf]", s, perl = TRUE)
  }

  for (i in seq_len(max_passes)) {
    suspicious <- looks_mojibake(x)
    if (!any(suspicious)) break

    repaired <- x
    # Re-encode the (wrongly decoded) characters back to their original
    # bytes, then reinterpret those bytes as UTF-8
    latin1_bytes <- iconv(x[suspicious], from = "UTF-8", to = "latin1", sub = "byte")
    Encoding(latin1_bytes) <- "UTF-8"
    is_valid <- !is.na(latin1_bytes) & validUTF8(latin1_bytes)
    repaired[suspicious][is_valid] <- latin1_bytes[is_valid]

    if (identical(repaired, x)) break
    x <- repaired
  }

  stringi::stri_trans_general(x, "Latin-ASCII")
}

#' Consolidate and Standardize Country Names and Assign ISO Codes
#'
#' Generic consolidation engine that applies country name consolidations,
#' removes diacritics, and assigns ISO 3-letter codes.
#'
#' @param combined_df Data frame with columns: year_n, country_en, and others
#' @param consolidation_mapping Data frame with columns: old_name, new_name, iso_code, reason
#'
#' @return Data frame with standardized country names, ISO codes, and metadata
#' @export
consolidate_and_standardize_countries <- function(combined_df, consolidation_mapping = NULL) {
  # Load default consolidation mapping if not provided
  if (is.null(consolidation_mapping)) {
    consolidation_mapping <- readr::read_csv(
      system.file("extdata", "consolidation_mapping.csv",
                  package = "pressfreedom.data"),
      show_col_types = FALSE
    )
  }
  # Copy original country names for audit trail
  result <- combined_df |>
    dplyr::mutate(
      country_name_original = .data$country_en,
      consolidation_flag = FALSE,
      .after = "country_en"
    )

  # Step 1: Handle territorial variants (pre-processing)
  result <- result |>
    dplyr::mutate(
      country_en_clean = dplyr::case_when(
        # DELETE: Israel occupied territories
        .data$country_en == "Israel (occupied territories)" ~ NA_character_,
        # DELETE: US in Iraq (raw RSF label spells it "Irak", not "Iraq")
        .data$country_en == "United States (in Irak)" ~ NA_character_,
        # DELETE: US outside territory
        .data$country_en == "United States (outside US territory)" ~ NA_character_,
        # CONSOLIDATE: Israel variants to "Israel"
        .data$country_en %in% c("Israel (Israeli territory)", "Israel (outside Israeli territory)") ~ "Israel",
        # CONSOLIDATE: US variants to "United States"
        .data$country_en == "United States (US territory)" ~ "United States",
        # Keep all others as-is for now
        TRUE ~ .data$country_en
      ),
      was_consolidated_territorial = .data$country_en != .data$country_en_clean & !is.na(.data$country_en_clean)
    )

  # Remove rows with NA country_en_clean (deleted territorial variants)
  result <- result |>
    dplyr::filter(!is.na(.data$country_en_clean))

  # When consolidating territorial variants, keep only the primary entry per year+cleaned_country
  # (when multiple variants map to same year+country, keep first, mark as consolidated)
  result <- result |>
    dplyr::group_by(.data$year_n, .data$country_en_clean) |>
    dplyr::mutate(
      consolidation_flag = .data$consolidation_flag | .data$was_consolidated_territorial,
      keep_row = dplyr::row_number() == 1
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(.data$keep_row) |>
    dplyr::select(-"keep_row", -"was_consolidated_territorial")

  # Update country_en with cleaned values
  result <- result |>
    dplyr::select(-"country_en") |>
    dplyr::rename(country_en = "country_en_clean")

  # Step 2: Apply name consolidations from mapping table
  for (i in seq_len(nrow(consolidation_mapping))) {
    old_name <- consolidation_mapping$old_name[i]
    new_name <- consolidation_mapping$new_name[i]

    result <- result |>
      dplyr::mutate(
        consolidation_flag = .data$consolidation_flag | (.data$country_en == old_name),
        country_en = dplyr::if_else(.data$country_en == old_name, new_name, .data$country_en)
      )
  }

  # Step 3: Repair mojibake and remove diacritics (ASCII normalization)
  # Both country_en and zone can arrive with UTF-8 bytes that were decoded
  # as Latin-1 one or more times by upstream tools (RSF source files,
  # readr::guess_encoding() misfires, etc.). repair_and_asciify() detects
  # and reverses that byte-level corruption generically -- however many
  # passes deep -- and then transliterates any genuinely accented
  # characters to ASCII. This replaces a previous approach of hand-listing
  # every known corrupted string as a regex substitution, which silently
  # missed variants (e.g. a single-pass mojibake of "Ameriques" was left
  # unrepaired because only the double-pass and already-correct forms had
  # been enumerated) and required a code change every time a new RSF
  # export introduced a new corrupted value.
  result <- result |>
    dplyr::mutate(
      country_en = repair_and_asciify(.data$country_en),
      zone = repair_and_asciify(.data$zone)
    )

  # Step 3b: Fix the 2022 zone classification anomaly
  # RSF's 2022 export used two non-standard zone labels ("Europe - Asie
  # centrale" and "Maghreb - Moyen-Orient") found in no other year. Remap
  # each affected country to whichever zone it uses in every other year,
  # so the dataset has a consistent six-zone classification throughout.
  zone_lookup <- result |>
    dplyr::filter(.data$year_n != 2022, !is.na(.data$zone)) |>
    dplyr::count(.data$country_en, .data$zone, name = "n_years") |>
    dplyr::group_by(.data$country_en) |>
    dplyr::slice_max(.data$n_years, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select("country_en", mapped_zone = "zone")

  result <- result |>
    dplyr::left_join(zone_lookup, by = "country_en") |>
    dplyr::mutate(
      zone = dplyr::if_else(
        .data$year_n == 2022 &
          .data$zone %in% c("Europe - Asie centrale", "Maghreb - Moyen-Orient") &
          !is.na(.data$mapped_zone),
        .data$mapped_zone,
        .data$zone
      )
    ) |>
    dplyr::select(-"mapped_zone")

  # Step 3c: Translate zone values from French to English
  # RSF's raw exports use six French-language zone labels. Every other
  # column in this dataset is English, so translate zone here to match --
  # this also permanently removes the recurring "zone mojibake" risk
  # (see repair_and_asciify() above): none of the six English names contain
  # a diacritic, so there is nothing left for an encoding glitch to corrupt.
  zone_mapping <- readr::read_csv(
    system.file("extdata", "zone_mapping.csv", package = "pressfreedom.data"),
    show_col_types = FALSE
  )
  zone_translation <- rlang::set_names(zone_mapping$new_name, zone_mapping$old_name)

  result <- result |>
    dplyr::mutate(
      zone = dplyr::if_else(
        .data$zone %in% names(zone_translation),
        unname(zone_translation[.data$zone]),
        .data$zone
      )
    )

  # Hard validation: fail loudly if any non-NA zone value isn't one of the
  # six approved English names, rather than letting an unrecognized value
  # slip through silently.
  approved_zones <- zone_mapping$new_name
  unexpected_zones <- result$zone[!is.na(result$zone) & !(result$zone %in% approved_zones)]
  if (length(unexpected_zones) > 0) {
    cli::cli_abort(c(
      "Unexpected {.field zone} value{?s} found after translation.",
      "x" = "Unrecognized: {unique(unexpected_zones)}",
      "i" = "Approved values: {approved_zones}"
    ))
  }

  # Step 4: Assign ISO codes
  result <- result |>
    dplyr::mutate(
      iso = countrycode::countrycode(
        sourcevar = .data$country_en,
        origin = "country.name",
        destination = "iso3c",
        warn = FALSE,
        nomatch = NA_character_
      ),
      # Handle special cases not caught by countrycode
      iso = dplyr::case_when(
        .data$country_en == "Cyprus" ~ "CYP",
        .data$country_en == "Northern Cyprus" ~ "CXX",  # Non-standard code for Turkish Republic of Northern Cyprus
        .data$country_en == "Congo-Brazzaville" ~ "COG",
        .data$country_en == "DR Congo" ~ "COD",
        .data$country_en == "Bosnia-Herzegovina" ~ "BIH",
        .data$country_en == "North Korea" ~ "PRK",
        .data$country_en == "Federal Republic of Yugoslavia" ~ "YUG",
        .data$country_en == "Serbia-Montenegro" ~ "SCG",
        .data$country_en == "Kosovo" ~ "XXK",
        .data$country_en == "Morocco / Western Sahara " ~ "MAR",  # Primary mapping to Morocco
        .data$country_en == "OECS" ~ "XXX",  # Organization of Eastern Caribbean States (regional, not country)
        # Catch corrupted Turkiye encoding variants
        grepl("rk.*ye", .data$country_en, ignore.case = TRUE) ~ "TUR",
        TRUE ~ .data$iso
      )
    )

  # Step 5: Ensure iso column is in correct position
  result <- result |>
    dplyr::relocate("iso", .after = "year_n")

  return(result)
}

#' Standardize RSF Country Data
#'
#' Main wrapper function for Phase D standardization pipeline.
#' Loads combined data, applies consolidations, assigns ISO codes,
#' and saves standardized output.
#'
#' @param input_file Path to combined RDS file
#' @param output_file Path to write standardized RDS file
#' @param mapping_file Path to consolidation mapping CSV
#'
#' @return Invisibly returns the path to the output file
#' @export
standardize_rwb_countries <- function(
    input_file = here::here("data", "processed", "rwb_combined.rds"),
    output_file = here::here("data", "processed", "rwb_standardized.rds"),
    mapping_file = NULL
) {
  # Load combined data
  combined <- readRDS(input_file)

  # Load consolidation mapping (use default if not provided)
  if (is.null(mapping_file)) {
    mapping <- readr::read_csv(
      system.file("extdata", "consolidation_mapping.csv",
                  package = "pressfreedom.data"),
      show_col_types = FALSE
    )
  } else {
    mapping <- readr::read_csv(mapping_file, show_col_types = FALSE)
  }

  # Apply standardization
  standardized <- consolidate_and_standardize_countries(combined, mapping)

  # Validate output
  validate_standardization(standardized, nrow(combined))

  # Save output
  saveRDS(standardized, output_file)

  # Pre-compute values for cli messaging (avoids environment scoping issues
  # while maintaining package-qualified function calls)
  n_rows <- nrow(standardized)
  n_countries_before <- dplyr::n_distinct(combined$country_en)
  n_countries_after <- dplyr::n_distinct(standardized$country_en)
  n_consolidations <- sum(standardized$consolidation_flag, na.rm = TRUE)

  cli::cli_alert_success("Standardization complete: {n_rows} rows")
  cli::cli_alert_info("Unique countries (before): {n_countries_before}")
  cli::cli_alert_info("Unique countries (after): {n_countries_after}")
  cli::cli_alert_info("Rows with consolidation_flag=TRUE: {n_consolidations}")
  cli::cli_alert_info("Output file: {output_file}")

  invisible(output_file)
}

#' Validate Standardization Output
#'
#' Check that standardization preserved data integrity and produced expected results.
#'
#' @param standardized Data frame with standardized country data
#' @param original_row_count Original number of rows (before consolidation)
#'
#' @return Invisibly returns TRUE if all checks pass
validate_standardization <- function(standardized, original_row_count) {
  issues <- c()

  # Check row count (may decrease due to deleted territorial variants)
  if (nrow(standardized) > original_row_count) {
    issues <- c(issues, "Row count increased (expected decrease or same)")
  }

  # Check critical columns exist
  required_cols <- c("year_n", "iso", "country_en", "score", "rank",
                     "country_name_original", "consolidation_flag")
  missing_cols <- setdiff(required_cols, names(standardized))
  if (length(missing_cols) > 0) {
    issues <- c(issues, paste("Missing columns:", paste(missing_cols, collapse = ", ")))
  }

  # Check for missing critical values
  critical_cols <- c("year_n", "iso", "country_en", "score", "rank")
  for (col in critical_cols) {
    if (col %in% names(standardized)) {
      n_missing <- sum(is.na(standardized[[col]]))
      if (n_missing > 0) {
        issues <- c(issues, paste("Column", col, "has", n_missing, "missing values"))
      }
    }
  }

  # Check for duplicate (year_n, country_en) pairs
  duplicates <- standardized |>
    dplyr::group_by(.data$year_n, .data$country_en) |>
    dplyr::filter(dplyr::n() > 1) |>
    nrow()
  if (duplicates > 0) {
    issues <- c(issues, paste(duplicates, "duplicate (year_n, country_en) pairs found"))
  }

  # Check ISO code coverage
  n_missing_iso <- sum(is.na(standardized$iso))
  if (n_missing_iso > 0) {
    missing_countries <- standardized |>
      dplyr::filter(is.na(.data$iso)) |>
      dplyr::distinct(.data$country_en) |>
      dplyr::pull("country_en")
    issues <- c(issues, paste("Missing ISO codes for:", paste(missing_countries, collapse = ", ")))
  }

  # Report results
  if (length(issues) > 0) {
    cli::cli_warn("Validation issues found:")
    for (issue in issues) {
      cli::cli_alert_danger(issue)
    }
    return(FALSE)
  } else {
    cli::cli_alert_success("All validation checks passed!")
    return(TRUE)
  }
}
