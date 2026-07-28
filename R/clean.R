#' Clean Period 1 Data (2002–2012)
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
#' 1. Read file with ISO-8859-1 encoding
#' 2. Convert decimal separators (comma → period)
#' 3. Rename columns per Period 1 mapping
#' 4. Convert iso, country_en, zone to character
#' 5. Convert numeric columns to numeric type
#' 6. Handle year_n for 2012 (raw data contains "2011-12" text value)
#' 7. Add NA columns for dimensions and score_evolution
#' 8. Reorder to target 20-column structure
#'
#' @keywords internal
#'
#' @export
clean_period_1 <- function(filepath, year) {
  # Read with ISO-8859-1 encoding, all columns as character
  # (readr auto-parses numeric columns which breaks comma decimal handling)
  df <- readr::read_delim(
    filepath,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "ISO-8859-1")
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


#' Clean Period 2 Data (2013–2021)
#'
#' Normalizes Period 2 raw data to the unified 20-column structure.
#' Identical structure to Period 1 (same columns, encoding).
#' Scores are comparable across 2013–2021 due to methodology introduced in 2013.
#'
#' @param filepath Character. Path to raw CSV file
#' @param year Numeric. Year of the data
#'
#' @return Data frame with 20 columns, standardized types (character, numeric)
#'
#' @keywords internal
#'
#' @export
clean_period_2 <- function(filepath, year) {
  # Process identically to Period 1 (same column names, encoding, structure)
  # Read with ISO-8859-1 encoding, all columns as character
  df <- readr::read_delim(
    filepath,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "ISO-8859-1")
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

  df
}


#' Clean Period 3 Data (2022–2026)
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
#' 1. Read file with UTF-8 encoding
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
#'
#' @export
clean_period_3 <- function(filepath, year) {
  # Read with UTF-8 encoding, all columns as character
  df <- readr::read_delim(
    filepath,
    delim = ";",
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8")
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

  # Convert numeric columns to numeric type
  numeric_target_cols <- c(
    "year_n", "score", "rank", "rank_n_1", "score_n_1", "rank_evolution",
    "political_context", "rank_pol", "economic_context", "rank_eco",
    "legal_context", "rank_leg", "social_context", "rank_soc",
    "safety", "rank_saf", "score_evolution"
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
#'
#' @export
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
#'
#' @export
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
