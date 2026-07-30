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
        # DELETE: US in Iraq
        .data$country_en == "US (in Iraq)" ~ NA_character_,
        # DELETE: US outside territory
        .data$country_en == "US (outside US territory)" ~ NA_character_,
        # CONSOLIDATE: Israel variants to "Israel"
        .data$country_en %in% c("Israel (Israeli territory)", "Israel (outside Israeli territory)") ~ "Israel",
        # CONSOLIDATE: US variants to "United States"
        .data$country_en == "US (US territory)" ~ "United States",
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

  # Step 3: Remove diacritics (ASCII normalization)
  # Use explicit gsub replacements for known problematic characters
  result <- result |>
    dplyr::mutate(
      country_en = .data$country_en |>
        stringr::str_replace_all("\u0043\u00f4\u0074\u0065", "Cote") |>
        stringr::str_replace_all("\u0054\u00fc\u0072\u006b\u0069\u0079\u0065", "Turkiye") |>
        stringr::str_replace_all("\u0043\u0075\u0072\u0061\u00e7\u0061\u006f", "Curacao") |>
        stringr::str_replace_all("\u0053\u00e3\u006f\u0020\u0054\u006f\u006d\u00e9", "Sao Tome") |>
        stringr::str_replace_all("\u0050\u0072\u00ed\u006e\u0063\u0069\u0070\u0065", "Principe") |>
        stringr::str_replace_all("\u0052\u00e9\u0075\u006e\u0069\u006f\u006e", "Reunion")
    )

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
