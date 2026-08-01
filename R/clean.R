#' Clean Period 1 Data (2002-2012)
#'
#' Normalizes Period 1 raw data to the unified 20-column structure.
#' Handles ISO-8859-1 encoding, decimal separator conversion, and column mapping.
#'
#' @param filepath Character. Path to raw CSV file
#' @param year Numeric. Year of the data
#'
#' @return Data frame with 20 columns, standardized types (character, numeric)
#'
#' @details
#' Processing steps:
#' 1. Detect file encoding (RSF's 2002-2021 exports are actually UTF-8,
#'    not ISO-8859-1 as originally assumed) and read accordingly
#' 2. Convert decimal separators (comma -> period)
#' 3. Rename columns per Period 1 mapping
#' 4. Convert iso, country_en, zone to character
#' 5. Convert numeric columns to numeric type
#' 6. Handle year_n for 2012 (raw data contains "2011-12" text value)
#' 7. Add NA columns for dimensions and score_evolution
#' 8. Reorder to target 20-column structure
#'
#' @keywords internal
clean_period_1 <- function(filepath, year) {
  # Detect encoding rather than assuming ISO-8859-1: RSF's Period 1-2 exports
  # are actually UTF-8, and hardcoding ISO-8859-1 here (paired with a
  # read/write round-trip at download time) previously double-encoded
  # accented characters and corrupted comma-decimal numbers
  detected_encoding <- detect_csv_encoding(filepath)

  # Read with detected encoding, all columns as character
  # (readr auto-parses numeric columns which breaks comma decimal handling)
  df <- readr::read_delim(
    filepath,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = detected_encoding)
  )

  # Identify numeric columns (score and rank columns) before renaming
  numeric_cols <- c("Score N", "Rank N", "Score N-1", "Rank N-1", "Rank evolution")
  numeric_cols <- numeric_cols[numeric_cols %in% names(df)]

  # Convert comma to period for numeric columns before type conversion
  if (length(numeric_cols) > 0) {
    df <- df |>
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of(numeric_cols),
          ~stringr::str_replace_all(as.character(.), ",", ".")
        )
      )
  }

  # Apply Period 1 column mapping
  mapping <- get_period_mapping("1", year)
  df <- normalize_column_names(df, "1", year, mapping)

  # Convert factor columns to character
  df <- convert_factors_to_character(df, c("iso", "country_en", "zone"))

  # Convert numeric columns to numeric type
  numeric_target_cols <- c(
    "year_n", "score", "rank", "rank_n_1", "score_n_1", "rank_evolution",
    "political_context", "rank_pol", "economic_context", "rank_eco",
    "legal_context", "rank_leg", "social_context", "rank_soc",
    "safety", "rank_saf"
  )
  df <- df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(numeric_target_cols),
        ~suppressWarnings(as.numeric(.))
      )
    )

  # Handle year_n for 2012: raw data contains "2011-12" which converts to NA
  # Fill with year parameter when all values are NA
  if (all(is.na(df$year_n))) {
    df <- df |>
      dplyr::mutate(year_n = year)
  }

  df
}


#' Resolve Missing-Trailing-Zero Score Scaling
#'
#' RSF's 2013+ exports store score/dimension percentages (0-100, 2 implied
#' decimal places) as bare digit strings with no decimal point (e.g. "9189"
#' means 91.89). Values ending in one or two zeros have those trailing
#' zeros silently dropped somewhere in RSF's own export pipeline (e.g. "844"
#' means 84.40, not 8.44; "87" means 87.00, not 0.87), which is
#' indistinguishable from a genuinely low sub-10 score for the
#' worst-ranked countries (e.g. "46" for a rank-180 country can legitimately
#' mean 0.46).
#'
#' @param raw_chr Character vector. Raw digit strings from the source CSV
#'   (no decimal point; may have a leading "-" for Period 1 legacy values).
#' @param rank_chr Character vector, same length as `raw_chr`. The
#'   corresponding rank column, used to disambiguate short values by
#'   comparing against neighboring, unambiguous (4+ digit) values at nearby
#'   ranks (scores are approximately monotonic in rank).
#'
#' @return Numeric vector of resolved percentages (0-100 scale).
#'
#' @details
#' Values with 4 or more digits are unambiguous ("confirmed"): a 4-digit
#' value is divided by 100 (2 implied decimals), and a small number of
#' 2025 rows have 5-digit values (RSF apparently breaks near-tied ranks
#' with a third decimal place, e.g. "65487" means 65.487, not 654.87), so
#' n-digit confirmed values are divided by `10^(n_digits - 2)` generally.
#' For shorter (2-3 digit) values, two candidates are computed:
#' right-padding with zeros to 4 digits before dividing by 100 (the
#' "dropped trailing zero" interpretation), and dividing the raw digits by
#' 100 directly (the "already complete, genuinely low score"
#' interpretation). The candidate closer to a rank-based linear
#' interpolation of neighboring confirmed values is selected. Missing rank
#' or missing value inputs fall back to the zero-padded interpretation.
#'
#' @keywords internal
resolve_percent_scaling <- function(raw_chr, rank_chr) {
  sign <- ifelse(stringr::str_starts(raw_chr, "-"), -1, 1)
  digits <- stringr::str_remove(raw_chr, "^-")
  n_digits <- nchar(digits)
  rank <- suppressWarnings(as.numeric(rank_chr))

  confirmed <- n_digits >= 4 & !is.na(digits) & digits != ""
  value <- rep(NA_real_, length(raw_chr))
  value[confirmed] <- as.numeric(digits[confirmed]) / 10^(n_digits[confirmed] - 2)

  # Reference points for interpolation: (rank, value) pairs from unambiguous
  # entries only, ordered by rank
  has_rank <- !is.na(rank)
  rank_order <- order(rank[has_rank])
  ref_rank <- rank[has_rank][rank_order][confirmed[has_rank][rank_order]]
  ref_value <- value[has_rank][rank_order][confirmed[has_rank][rank_order]]

  for (i in which(!confirmed)) {
    d <- digits[i]
    if (is.na(d) || d == "") next

    n_d <- nchar(d)
    cand_padded <- as.numeric(paste0(d, strrep("0", 4 - n_d))) / 100
    cand_direct <- as.numeric(d) / 100

    expected <- if (is.na(rank[i]) || length(ref_rank) < 2) {
      NA_real_
    } else {
      suppressWarnings(
        stats::approx(ref_rank, ref_value, xout = rank[i], rule = 2)$y
      )
    }

    value[i] <- if (is.na(expected)) {
      cand_padded
    } else if (abs(cand_padded - expected) <= abs(cand_direct - expected)) {
      cand_padded
    } else {
      cand_direct
    }
  }

  sign * value
}


#' Clean Period 2 Data (2013-2021)
#'
#' Normalizes Period 2 raw data to the unified 20-column structure.
#' Identical structure to Period 1 (same columns, encoding).
#' Scores are comparable across 2013-2021 due to methodology introduced in 2013.
#'
#' @param filepath Character. Path to raw CSV file
#' @param year Numeric. Year of the data
#'
#' @return Data frame with 20 columns, standardized types (character, numeric)
#'
#' @keywords internal
clean_period_2 <- function(filepath, year) {
  # Process identically to Period 1 (same column names, structure); detect
  # encoding per file rather than assuming ISO-8859-1 (see clean_period_1())
  detected_encoding <- detect_csv_encoding(filepath)

  df <- readr::read_delim(
    filepath,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = detected_encoding)
  )

  # Identify numeric columns (score and rank columns) before renaming
  numeric_cols <- c("Score N", "Rank N", "Score N-1", "Rank N-1", "Rank evolution")
  numeric_cols <- numeric_cols[numeric_cols %in% names(df)]

  # Convert comma to period for numeric columns before type conversion
  if (length(numeric_cols) > 0) {
    df <- df |>
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of(numeric_cols),
          ~stringr::str_replace_all(as.character(.), ",", ".")
        )
      )
  }

  # Apply Period 2 column mapping
  mapping <- get_period_mapping("2", year)
  df <- normalize_column_names(df, "2", year, mapping)

  # Convert factor columns to character
  df <- convert_factors_to_character(df, c("iso", "country_en", "zone"))

  # "score" is always on the 2013+ comparable scale and needs trailing-zero
  # resolution. "score_n_1" only needs it from 2014 onward: for year 2013,
  # score_n_1 carries Period 1's non-comparable legacy value verbatim (see
  # AGENTS.md), which has no implied 2-decimal scaling to resolve
  df <- df |>
    dplyr::mutate(
      score = resolve_percent_scaling(.data$score, .data$rank),
      score_n_1 = if (year > 2013) {
        resolve_percent_scaling(.data$score_n_1, .data$rank_n_1)
      } else {
        suppressWarnings(as.numeric(.data$score_n_1))
      }
    )

  # Convert remaining numeric columns to numeric type (score/score_n_1
  # already resolved above)
  numeric_target_cols <- c(
    "year_n", "rank", "rank_n_1", "rank_evolution",
    "political_context", "rank_pol", "economic_context", "rank_eco",
    "legal_context", "rank_leg", "social_context", "rank_soc",
    "safety", "rank_saf"
  )
  df <- df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(numeric_target_cols),
        ~suppressWarnings(as.numeric(.))
      )
    )

  df
}


#' Detect CSV File Encoding
#'
#' Guesses whether a raw RSF CSV file is UTF-8 or a Latin-1 variant.
#' Used by clean_period_1(), clean_period_2(), and clean_period_3() because
#' RSF has switched export encoding across years without notice (e.g.
#' 2002-2021 exports are UTF-8 despite once being assumed ISO-8859-1, and
#' 2025-2026 arrived as ISO-8859-1 while 2022-2024 were UTF-8).
#'
#' @param filepath Character. Path to raw CSV file
#'
#' @return Character. Either "UTF-8" or "ISO-8859-1"
#'
#' @details
#' Uses readr::guess_encoding(), which ranks candidate encodings by
#' confidence. Falls back to "UTF-8" if detection is inconclusive, since
#' that has been the more common case historically.
#'
#' @keywords internal
detect_csv_encoding <- function(filepath) {
  guesses <- readr::guess_encoding(filepath)

  if (nrow(guesses) == 0) {
    return("UTF-8")
  }

  top_guess <- guesses$encoding[1]

  # Normalize any Latin-1/Windows-1252 family guess to ISO-8859-1, which
  # readr's locale() understands and which covers the accented characters
  # RSF's exports use
  if (grepl("^(ISO-8859-1|windows-1252|latin1)$", top_guess, ignore.case = TRUE)) {
    return("ISO-8859-1")
  }

  "UTF-8"
}


#' Clean Period 3 Data (2022-2026)
#'
#' Normalizes Period 3 raw data to the unified 20-column structure.
#' Handles UTF-8 encoding, year-specific score column naming,
#' dimension columns, and decimal separator conversion for score_evolution.
#'
#' @param filepath Character. Path to raw CSV file
#' @param year Numeric. Year of the data
#'
#' @return Data frame with 20 columns, standardized types (character, numeric)
#'
#' @details
#' Processing steps:
#' 1. Detect file encoding (RSF has silently switched between UTF-8 and
#'    ISO-8859-1 across Period 3 years, e.g. 2025-2026 exports arrived as
#'    Latin-1 even though 2022-2024 were UTF-8) and read accordingly
#' 2. Detect score column name (Score, Score YYYY, etc.)
#' 3. Drop problematic columns (Situation, etc.)
#' 4. Rename columns per Period 3 mapping
#' 5. Convert iso, country_en, zone to character
#' 6. Convert numeric columns to numeric type
#' 7. Apply decimal separator conversion to all numeric columns (handles score_evolution)
#' 8. Set score_n_1 and score_evolution to NA for 2022
#' 9. Reorder to target 20-column structure
#'
#' @keywords internal
clean_period_3 <- function(filepath, year) {
  # RSF has changed export encoding across Period 3 years without notice
  # (2022-2024 files are UTF-8; 2025-2026 arrived as ISO-8859-1/Latin-1).
  # Detect encoding per file instead of assuming UTF-8, so silent switches
  # don't produce strings mismarked as UTF-8 that later fail nchar()/View().
  detected_encoding <- detect_csv_encoding(filepath)

  df <- readr::read_delim(
    filepath,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = detected_encoding)
  )

  # Drop problematic columns (Situation, etc.)
  cols_to_drop <- c("Situation")
  cols_to_drop <- cols_to_drop[cols_to_drop %in% names(df)]
  if (length(cols_to_drop) > 0) {
    df <- df |> dplyr::select(-dplyr::all_of(cols_to_drop))
  }

  # Apply Period 3 column mapping
  mapping <- get_period_mapping("3", year)
  df <- normalize_column_names(df, "3", year, mapping)

  # Convert factor columns to character
  df <- convert_factors_to_character(df, c("iso", "country_en", "zone"))

  # "score", "score_n_1", and the five dimension columns are stored as bare
  # digit strings with an implied 2-decimal scaling (e.g. "9189" = 91.89)
  # and need trailing-zero resolution before generic numeric conversion.
  # score_n_1 is NA for 2022 (no history columns in that year's export;
  # normalize_column_names already sets it to NA) and a raw 4/5-digit
  # string for 2023+, exactly like "score" -- resolve_percent_scaling()
  # handles NA input safely (returns NA), so it's included unconditionally
  # rather than branching on year.
  percent_cols <- c(
    "score", "score_n_1", "political_context", "economic_context",
    "legal_context", "social_context", "safety"
  )
  rank_for_col <- c(
    score = "rank", score_n_1 = "rank_n_1", political_context = "rank_pol",
    economic_context = "rank_eco", legal_context = "rank_leg",
    social_context = "rank_soc", safety = "rank_saf"
  )
  for (col in percent_cols) {
    if (col %in% names(df)) {
      df[[col]] <- resolve_percent_scaling(df[[col]], df[[rank_for_col[[col]]]])
    }
  }

  # Convert numeric columns to numeric type (score/score_n_1 and dimension
  # columns already resolved above)
  numeric_target_cols <- c(
    "year_n", "rank", "rank_n_1", "rank_evolution",
    "rank_pol", "rank_eco", "rank_leg", "rank_soc", "rank_saf",
    "score_evolution"
  )
  # Only convert columns that exist
  numeric_to_convert <- numeric_target_cols[numeric_target_cols %in% names(df)]
  if (length(numeric_to_convert) > 0) {
    # Convert comma to period for numeric columns (handles score_evolution decimal separators)
    df <- df |>
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of(numeric_to_convert),
          ~suppressWarnings(as.numeric(stringr::str_replace_all(as.character(.), ",", ".")))
        )
      )
  }

  # Note: score_n_1 and score_evolution are already NA for 2022
  # (set by normalize_column_names since those columns don't exist in raw data)

  df
}


#' Clean Single Year of RSF Data
#'
#' Dispatcher function that routes to appropriate period-specific cleaner.
#' Reads raw CSV, applies period-specific transformations, saves as RDS.
#'
#' @param filepath Character. Path to raw CSV file
#' @param year Numeric. Year of the data
#' @param output_dir Character. Directory to save cleaned RDS file
#'
#' @return Invisible. Writes RDS file to output_dir.
#'   Filename format: rwbYYYY_cleaned.rds
#'
#' @details
#' This function:
#' 1. Detects period from year using get_period()
#' 2. Routes to clean_period_1(), clean_period_2(), or clean_period_3()
#' 3. Validates output has 20 columns in correct order
#' 4. Saves as RDS file in output_dir
#' 5. Returns invisible filepath (for logging/progress tracking)
#'
#' @keywords internal
clean_rwb_single <- function(filepath, year, output_dir) {
  # Detect period
  period <- get_period(year)
  if (is.na(period)) {
    cli::cli_abort("Cannot determine period for year {year}")
  }

  # Convert period to numeric (1, 2, or 3)
  period_num <- as.numeric(stringr::str_extract(period, "\\d"))

  # Route to appropriate cleaner
  df <- switch(period_num,
    "1" = clean_period_1(filepath, year),
    "2" = clean_period_2(filepath, year),
    "3" = clean_period_3(filepath, year),
    cli::cli_abort("Unknown period: {period}")
  )

  # Validate output structure
  if (nrow(df) == 0) {
    cli::cli_warn("Year {year}: No rows in cleaned data")
  }

  if (ncol(df) != 20) {
    cli::cli_abort(
      "Year {year}: Expected 20 columns, got {ncol(df)}"
    )
  }

  if (!identical(names(df), target_columns)) {
    cli::cli_abort(
      "Year {year}: Column order mismatch.\\nExpected: {toString(target_columns)}\\nGot: {toString(names(df))}"
    )
  }

  # Create output directory if needed
  if (!dir.exists(output_dir)) {
    fs::dir_create(output_dir, recurse = TRUE)
  }

  # Save as RDS
  output_file <- fs::path(output_dir, glue::glue("rwb{year}_cleaned.rds"))
  readr::write_rds(df, output_file)

  # Return invisible filepath
  invisible(output_file)
}


#' Batch Clean All RSF Years
#'
#' Processes all available raw CSV files and produces cleaned RDS files.
#' Automatically detects period for each year and applies appropriate transformations.
#'
#' @param input_dir Character. Directory containing raw CSV files.
#'   Defaults to inst/extdata
#' @param output_dir Character. Directory to save cleaned RDS files.
#'   Defaults to data/cleaned
#'
#' @return Data frame with processing summary:
#'   - year: Year processed
#'   - period: Period (1, 2, or 3)
#'   - status: "success" or "error"
#'   - message: Details or error message
#'   - output_file: Path to cleaned RDS (if successful)
#'
#' @details
#' This function:
#' 1. Lists all rwbYYYY.csv files in input_dir
#' 2. Extracts years and detects periods
#' 3. Calls clean_rwb_single() for each year
#' 4. Catches and logs errors for failed years
#' 5. Creates period-specific subdirectories (period_1/, period_2/, period_3/)
#' 6. Returns summary of processing results
#'
#' Processing proceeds in year order (2002-2026, excluding 2011).
#' Skips years without data files.
#'
#' @keywords internal
clean_all_rwb_years <- function(
    input_dir = here::here("inst/extdata"),
    output_dir = here::here("data/cleaned")) {
  # List all raw CSV files
  raw_files <- list.files(
    input_dir,
    pattern = "^rwb\\d{4}\\.csv$",
    full.names = TRUE
  )

  if (length(raw_files) == 0) {
    cli::cli_inform("No raw CSV files found in {input_dir}")
    return(tibble::tibble())
  }

  # Extract years from filenames
  years <- as.numeric(sub("^.*rwb(\\d{4})\\.csv$", "\\1", raw_files))

  # Sort by year
  order_idx <- order(years)
  raw_files <- raw_files[order_idx]
  years <- years[order_idx]

  # Process each year
  results <- list()
  for (i in seq_along(years)) {
    year <- years[i]
    filepath <- raw_files[i]

    # Detect period and create period-specific output dir
    period <- get_period(year)
    period_num <- as.numeric(stringr::str_extract(period, "\\d"))
    period_dir <- fs::path(output_dir, glue::glue("period_{period_num}"))

    # Process with error handling
    result <- tryCatch(
      {
        output_file <- clean_rwb_single(filepath, year, period_dir)
        list(
          year = year,
          period = period_num,
          status = "success",
          message = "Cleaned and saved",
          output_file = as.character(output_file)
        )
      },
      error = function(e) {
        list(
          year = year,
          period = period_num,
          status = "error",
          message = conditionMessage(e),
          output_file = NA_character_
        )
      }
    )

    results[[i]] <- result
  }

  # Convert list of lists to data frame
  summary <- results |>
    purrr::map_df(~tibble::as_tibble(as.list(.)))

  # Print summary
  n_success <- sum(summary$status == "success")
  n_error <- sum(summary$status == "error")

  cli::cli_inform(
    "\\nCleaning complete: {n_success} successful, {n_error} errors"
  )

  if (n_error > 0) {
    cli::cli_warn("Years with errors: {toString(summary$year[summary$status == 'error'])}")
  }

  summary
}
