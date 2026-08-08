#' Combine Cleaned RDS Files from All Periods
#'
#' Reads all cleaned RDS files from period_1, period_2, and period_3
#' directories and combines them into a single data frame.
#'
#' @param input_dir Directory containing period subdirectories (period_1, period_2, period_3).
#'   Required (no default) so the function never reads from a package or
#'   home directory implicitly.
#' @param output_file Path where combined RDS file should be saved.
#'   Required (no default) so the function never writes to a package or
#'   home directory implicitly.
#'
#' @return Invisibly returns the path to the output file
#'
#' @keywords internal
combine_cleaned_periods <- function(
    input_dir,
    output_file
) {
  # Ensure output directory exists
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Define period directories
  periods <- c("period_1", "period_2", "period_3")
  all_files <- character(0)

  # Collect all RDS files from each period directory
  for (period in periods) {
    period_dir <- file.path(input_dir, period)
    if (dir.exists(period_dir)) {
      files <- list.files(
        period_dir,
        pattern = "^rwb.*_cleaned\\.rds$",
        full.names = TRUE
      )
      all_files <- c(all_files, files)
    }
  }

  if (length(all_files) == 0) {
    cli::cli_abort("No cleaned RDS files found in {input_dir}")
  }

  # Read and combine all files
  # Note: Fix issues that occurred during B1 normalization
  combined_data <- purrr::map_df(all_files, function(file) {
    df <- readRDS(file)
    
    # Extract year from filename (rwbYYYY_cleaned.rds)
    filename_year <- as.numeric(gsub(".*rwb(\\d+)_cleaned\\.rds", "\\1", basename(file)))
    
    # If year_n is all NA (occurs in 2012 file which contains 2011-12 data),
    # fill with the file year (2012 by design)
    if (all(is.na(df$year_n))) {
      df$year_n <- filename_year
    }
    
    # If score_evolution is character, convert comma decimals to periods
    if (is.character(df$score_evolution)) {
      df$score_evolution <- as.numeric(
        gsub(",", ".", df$score_evolution, fixed = TRUE)
      )
    }
    
    return(df)
  })

  # Verify structure
  expected_cols <- c(
    "year_n", "iso", "country_en", "score", "rank",
    "political_context", "rank_pol", "economic_context", "rank_eco",
    "legal_context", "rank_leg", "social_context", "rank_soc",
    "safety", "rank_saf", "zone", "rank_n_1", "rank_evolution",
    "score_n_1", "score_evolution"
  )

  missing_cols <- setdiff(expected_cols, names(combined_data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "Combined data missing columns: {paste(missing_cols, collapse = ', ')}"
    )
  }

  extra_cols <- setdiff(names(combined_data), expected_cols)
  if (length(extra_cols) > 0) {
    cli::cli_warn(
      "Combined data has unexpected columns: {paste(extra_cols, collapse = ', ')}"
    )
  }

  # Arrange by year and country for consistency
  combined_data <- combined_data |>
    dplyr::arrange(.data$year_n, .data$country_en)

  # Save combined file
  saveRDS(combined_data, output_file)

  cli::cli_inform(
    c(
      "v" = "Combined {nrow(combined_data)} rows from {length(all_files)} files",
      "v" = "Columns: {ncol(combined_data)}",
      "v" = "Saved to: {output_file}"
    )
  )

  invisible(output_file)
}
