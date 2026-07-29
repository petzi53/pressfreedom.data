#' Update RSF Press Freedom Index Data
#'
#' Incremental data update script. Run annually when RSF publishes new data.
#' Downloads only missing years—no re-downloads of existing files.
#'
#' This script:
#' 1. Checks which years are missing from inst/extdata/
#' 2. Downloads only those years
#' 3. Reports status with dynamic year range (no hard-coded values)

# Load the package
devtools::load_all()

# Check which years are missing
missing <- get_years_to_download()

if (length(missing) > 0) {
  cat("Downloading missing years:", paste(missing, collapse = ", "), "\n")
  download_rwb_data(years = missing)
  
  # Report success with dynamic range
  all_files <- list.files("inst/extdata/", pattern = "^rwb\\d{4}\\.csv$")
  all_years <- as.integer(sub("^rwb(\\d{4})\\.csv$", "\\1", all_files))
  all_years <- sort(all_years)
  
  year_range <- paste(min(all_years), max(all_years), sep = "-")
  cat("\nSuccess! Dataset now contains years:", year_range, 
      "(", length(all_years), "files, excluding 2011 )\n")
} else {
  # Report current state dynamically
  all_files <- list.files("inst/extdata/", pattern = "^rwb\\d{4}\\.csv$")
  all_years <- as.integer(sub("^rwb(\\d{4})\\.csv$", "\\1", all_files))
  all_years <- sort(all_years)
  
  year_range <- paste(min(all_years), max(all_years), sep = "-")
  cat("All years already present:", year_range, 
      "(", length(all_years), "files, excluding 2011 )\n")
}
