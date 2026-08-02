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
#' RSF publishes press freedom index data at a per-year URL template (not a
#' literal link, since \code{<year>} must be substituted, e.g. \code{2024}):
#' \verb{https://rsf.org/sites/default/files/import_classement/<year>.csv}
#'
#' **Encoding Handling:**
#' Files are downloaded as raw bytes (\code{utils::download.file(mode = "wb")})
#' and written to disk unmodified. No parsing, re-encoding, or re-serialization
#' happens at download time, so whatever bytes RSF serves (RSF has used both
#' UTF-8 and ISO-8859-1/Latin-1 depending on the year, without warning) are
#' preserved exactly as-is. Encoding is detected later, per file, when the data
#' is cleaned (see \code{detect_csv_encoding()}).
#'
#' An earlier version of this function read each file with
#' \code{readr::read_delim()} using a period-based encoding guess and then
#' re-wrote it with \code{readr::write_delim()}. That round-trip silently
#' corrupted the 2002-2021 files (which are actually UTF-8, not ISO-8859-1 as
#' assumed): text was double-encoded and numeric columns like \code{Score N}
#' were mis-parsed (commas treated as thousands separators, e.g. "92,48"
#' became 9248). Downloading raw bytes avoids this class of bug entirely.
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
#' @keywords internal
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
        # Download raw bytes with no parsing/re-encoding, so the file on disk
        # is byte-identical to what RSF served (see @details for why a
        # previous read/write round-trip was harmful)
        utils::download.file(
          url,
          destfile = filename,
          mode = "wb",
          quiet = TRUE
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
