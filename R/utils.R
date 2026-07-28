#' Detect RSF Data Period by Year
#'
#' Determines which structural period a given year belongs to based on known
#' changes in RSF's data format and calculation methodology.
#'
#' @param year Integer. Year to check.
#'
#' @return Character. One of: \code{"period_1"} (2002-2012), \code{"period_2"}
#'   (2013-2021), or \code{"period_3"} (2022-2026). Returns \code{NA} for
#'   year 2011 (no official RSF data).
#'
#' @details
#' **Period 1 (2002-2012):**
#' - 16 columns with fixed structure
#' - Encoding: ISO-8859-1
#' - Delimiter: semicolon (;)
#' - Scores not comparable across years (within-year ranks only)
#'
#' **Period 2 (2013-2021):**
#' - 16 columns, same structure as Period 1
#' - Encoding: ISO-8859-1
#' - Delimiter: semicolon (;)
#' - Scores comparable across years (new calculation method introduced)
#'
#' **Period 3 (2022-2026):**
#' - 22-25 columns (varies by year)
#' - Encoding: UTF-8
#' - Delimiter: semicolon (;)
#' - Major restructuring: columns reordered, score dimensions added
#' - Column names vary by year (e.g., "Score" vs "Score 2026")
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' get_period(2005)   # "period_1"
#' get_period(2015)   # "period_2"
#' get_period(2024)   # "period_3"
#' get_period(2011)   # NA
#' }
#'
#' @export
get_period <- function(year) {
  if (year == 2011) {
    return(NA_character_)
  } else if (year %in% 2002:2012) {
    "period_1"
  } else if (year %in% 2013:2021) {
    "period_2"
  } else if (year %in% 2022:2026) {
    "period_3"
  } else {
    NA_character_
  }
}


#' Get Encoding for RSF Data by Period
#'
#' Returns the appropriate text encoding for reading RSF CSV files based on
#' data period.
#'
#' @param year Integer. Year to check.
#'
#' @return Character. Encoding string: \code{"ISO-8859-1"} for Period 1-2,
#'   \code{"UTF-8"} for Period 3.
#'
#' @details
#' **ISO-8859-1 (Latin-1):** Periods 1-2 (2002-2021)
#' **UTF-8:** Period 3 (2022-2026)
#'
#' @keywords internal
#'
#' @export
get_period_encoding <- function(year) {
  period <- get_period(year)
  if (is.na(period)) {
    return(NA_character_)
  }
  if (period %in% c("period_1", "period_2")) {
    "ISO-8859-1"
  } else {
    "UTF-8"
  }
}


#' Get Years That Need Downloading
#'
#' Compares available CSV files in the input directory against a full list of
#' years to identify which years are missing. Automatically excludes 2011
#' (no official RSF data).
#'
#' @param input_dir Character. Directory path containing downloaded CSV files.
#'   Defaults to \code{"inst/extdata"}.
#' @param all_years Integer vector. All years to check for.
#'   Defaults to \code{2002:2026}.
#'
#' @return Integer vector of years that don't have corresponding CSV files.
#'   Returns empty vector if all years are present.
#'
#' @details
#' This is a utility function useful for incremental updates. For example, when
#' a new year of data becomes available at RSF, use this function to detect
#' which years need downloading without re-downloading existing data.
#'
#' Note: Year 2011 is never included in the returned vector, even if it's
#' in the \code{all_years} range.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Check which years are missing locally
#' missing_years <- get_years_to_download()
#' missing_years
#' }
#'
#' @export
get_years_to_download <- function(input_dir = "inst/extdata", all_years = 2002:2026) {
  # Exclude 2011 (no official RSF data)
  all_years <- setdiff(all_years, 2011)

  if (!dir.exists(input_dir)) {
    return(all_years)
  }

  # List existing CSV files
  existing_files <- list.files(input_dir, pattern = "^rwb\\d{4}\\.csv$")

  # Extract years from filenames (e.g., "rwb2020.csv" -> 2020)
  existing_years <- as.integer(sub("^rwb(\\d{4})\\.csv$", "\\1", existing_files))

  # Return years that don't exist yet
  setdiff(all_years, existing_years)
}


#' Standardize Decimal Separators
#'
#' Converts comma decimal separators to periods for Period 1–2 data
#' (ISO-8859-1 encoded data used commas as decimal separators).
#'
#' @param df Data frame to process
#' @param cols Character vector of column names to standardize
#'
#' @return Data frame with decimal separators converted from comma to period
#'
#' @details
#' This function targets numeric columns that may contain comma separators.
#' It is primarily for Period 1–2 data where European number formatting was used.
#'
#' @keywords internal
#'
#' @export
standardize_decimal_separators <- function(df, cols) {
  df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(cols),
        ~stringr::str_replace_all(as.character(.), ",", ".")
      )
    )
}


#' Convert Factor Columns to Character
#'
#' Converts specified factor columns to character vectors.
#' Used to standardize iso, country_en, and zone columns to character type.
#'
#' @param df Data frame to process
#' @param cols Character vector of column names to convert
#'
#' @return Data frame with specified columns converted to character
#'
#' @keywords internal
#'
#' @export
convert_factors_to_character <- function(df, cols) {
  df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(cols),
        ~as.character(.)
      )
    )
}


#' Detect Score Column Name for Period 3
#'
#' Period 3 (2022-2026) uses varying score column names.
#' Some years use "Score", others use "Score YYYY".
#' This function detects which pattern is present.
#'
#' @param df Data frame to inspect
#' @param year Numeric. Year of the data
#'
#' @return Character. Name of the score column (e.g., "Score" or "Score 2026")
#'
#' @details
#' Detection logic:
#' - Check for "Score YYYY" pattern first (e.g., "Score 2026")
#' - Fall back to "Score" if year-specific name not found
#' - Return NA if neither found
#'
#' @keywords internal
#'
#' @export
detect_score_column <- function(df, year) {
  # Try year-specific name first (e.g., "Score 2026")
  year_col <- paste("Score", year)
  if (year_col %in% names(df)) {
    return(year_col)
  }

  # Fall back to generic "Score"
  if ("Score" %in% names(df)) {
    return("Score")
  }

  # Not found
  NA_character_
}


#' Normalize Column Names to Target Structure
#'
#' Applies period-specific column mappings to raw data.
#' Renames columns and adds NA columns for missing data.
#'
#' @param df Data frame to normalize
#' @param period Character. One of "1", "2", or "3"
#' @param year Numeric. Year of the data (used for Period 3 score detection)
#' @param mapping List. Column mapping dictionary
#'
#' @return Data frame with normalized column names in target order
#'
#' @details
#' This function:
#' 1. Detects the score column name for Period 3
#' 2. Renames raw columns to target names
#' 3. Adds NA columns for missing data
#' 4. Reorders to match target column order
#'
#' @keywords internal
#'
#' @export
normalize_column_names <- function(df, period, year, mapping) {
  # Handle Period 3 score column detection
  if (period == "3") {
    score_col <- detect_score_column(df, year)
    if (!is.na(score_col)) {
      mapping$score <- score_col
    }
  }

  # Separate NA mappings from real mappings
  all_mapping_values <- unlist(mapping)
  real_cols <- names(mapping)[!is.na(all_mapping_values)]
  na_cols <- names(mapping)[is.na(all_mapping_values)]

  # Rename existing columns one by one to avoid issues with all_of
  # Only rename columns that actually exist in the dataframe
  for (target_col in real_cols) {
    raw_col <- mapping[[target_col]]
    if (!is.na(raw_col) && raw_col %in% names(df)) {
      df <- df |> dplyr::rename(!!target_col := !!rlang::sym(raw_col))
    }
  }

  # Add NA columns for all missing columns
  # This includes both explicitly NA-mapped columns and columns not found in raw data
  for (target_col in target_columns) {
    if (!target_col %in% names(df)) {
      df[[target_col]] <- NA_real_
    }
  }

  # Reorder to target column order
  df |> dplyr::select(dplyr::all_of(target_columns))
}
