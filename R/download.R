#' Download RSF Press Freedom Index Data
#'
#' Downloads press freedom index CSV files from Reporters Without Borders (RSF)
#' for specified years. Files are saved as-is (unmodified) with consistent
#' naming (\code{rwb<year>.csv}).
#'
#' @param years Integer vector. Years to download. Defaults to \code{2002:2026}.
#' @param output_dir Character. Directory path where CSV files will be saved.
#'   Defaults to \code{"inst/extdata"}. Directory is created if it doesn't exist.
#' @param skip_missing Logical. If \code{TRUE}, automatically skips year 2011
#'   (no official RSF data published). Defaults to \code{TRUE}.
#'
#' @return Invisibly returns a named list where names are years and values
#'   indicate success/failure status. Called for side effects (downloading files).
#'
#' @details
#' RSF publishes press freedom index data at:
#' \url{https://rsf.org/sites/default/files/import_classement/<year>.csv}
#'
#' **Encoding Handling:**
#' Files are read and written using period-aware encoding:
#' - Periods 1-2 (2002-2021): ISO-8859-1 (Latin-1)
#' - Period 3 (2022-2026): UTF-8
#'
#' This preserves the original encoding as provided by RSF.
#'
#' Year 2011 is not available; no imputation is performed. If
#' \code{skip_missing = TRUE}, the function automatically filters out 2011
#' before downloading.
#'
#' Error Handling:
#' - Connection failures are logged but don't stop the function
#' - HTTP 404 errors (missing years) are logged as warnings
#' - File write permission errors are caught and reported
#'
#' @examples
#' \dontrun{
#' # Download all years (excluding 2011) to default directory
#' download_rwb_data()
#'
#' # Download specific years to custom directory
#' download_rwb_data(years = 2020:2026, output_dir = "inst/extdata")
#' }
#'
#' @export
#'
download_rwb_data <- function(years = 2002:2026,
                              output_dir = "inst/extdata",
                              skip_missing = TRUE) {
  # Validate inputs
  if (!is.numeric(years) || !all(years == as.integer(years))) {
    rlang::abort("'years' must be an integer vector")
  }

  if (!is.character(output_dir) || length(output_dir) != 1) {
    rlang::abort("'output_dir' must be a single character string")
  }

  # Remove 2011 if skip_missing is TRUE
  if (skip_missing) {
    years <- setdiff(years, 2011)
  }

  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Resolve relative paths
  output_dir <- here::here(output_dir)

  results <- list()

  for (year in years) {
    url <- sprintf("https://rsf.org/sites/default/files/import_classement/%d.csv", year)
    filename <- file.path(output_dir, sprintf("rwb%d.csv", year))

    tryCatch(
      {
        # Get encoding for this year's period
        encoding <- get_period_encoding(year)

        # Download CSV with period-appropriate encoding
        data <- readr::read_delim(
          url,
          delim = ";",
          locale = readr::locale(encoding = encoding),
          show_col_types = FALSE
        )

        # Write back with same encoding (preserves as-is)
        readr::write_delim(
          data,
          filename,
          delim = ";",
          na = ""
        )

        cat("[OK] Downloaded:", filename, "\n")
        results[[as.character(year)]] <- TRUE
      },
      error = function(e) {
        # Log error but continue with next year
        if (grepl("404", e$message, ignore.case = TRUE)) {
          warning("Year ", year, " not found at RSF (HTTP 404)", call. = FALSE)
        } else {
          warning("Failed to download year ", year, ": ", e$message, call. = FALSE)
        }
        results[[as.character(year)]] <<- FALSE
      }
    )
  }

  # Print summary
  successful <- sum(unlist(results))
  total <- length(results)
  cat("\n=== Download Summary ===\n")
  cat("Successful:", successful, "/", total, "\n")
  cat("Location:", output_dir, "\n")

  invisible(results)
}
