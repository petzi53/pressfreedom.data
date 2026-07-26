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
