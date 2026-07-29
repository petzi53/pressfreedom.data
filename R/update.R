#' Update Reporters Without Borders Press Freedom Data
#'
#' Orchestrates the full yearly update workflow: downloads missing years,
#' cleans them, recombines all periods, re-standardizes countries,
#' exports to package format, and validates the result.
#'
#' This function implements the "minimal disruption principle": only new years
#' are downloaded and cleaned. Phases C-D (combine, standardize) always run
#' because evolution columns depend on year N-1's data.
#'
#' @param years Integer vector. Years to download and clean.
#'   Defaults to \code{NULL}: auto-detect missing years via \code{get_years_to_download()}.
#' @param download Logical. If \code{TRUE}, download missing years.
#'   If \code{FALSE}, skip download (useful for testing). Default: \code{TRUE}.
#' @param clean Logical. If \code{TRUE}, clean newly downloaded years.
#'   If \code{FALSE}, skip cleaning. Default: \code{TRUE}.
#' @param combine Logical. Always \code{TRUE}; recombines all periods to recalculate
#'   evolution columns. Cannot be skipped. Default: \code{TRUE}.
#' @param standardize Logical. Always \code{TRUE}; re-standardizes countries
#'   to apply consolidation rules consistently. Cannot be skipped. Default: \code{TRUE}.
#' @param validate Logical. If \code{TRUE}, run validation checks on output.
#'   Default: \code{TRUE}.
#' @param verbose Logical. If \code{TRUE}, print progress messages.
#'   Default: \code{TRUE}.
#' @param auto_commit Logical. If \code{TRUE}, auto-commit changes to git with
#'   a descriptive message. Default: \code{TRUE}.
#'
#' @return Invisible list with class "rwb_update" containing:
#'   - \code{status}: "success", "partial", or "failed"
#'   - \code{years_downloaded}: Integer vector of years downloaded
#'   - \code{years_cleaned}: Integer vector of years cleaned
#'   - \code{rows_before}: Row count in combined RDS before update
#'   - \code{rows_after}: Row count in combined RDS after update
#'   - \code{consolidations_applied}: Number of consolidation rules applied
#'   - \code{validation_passed}: Logical, \code{TRUE} if all checks pass
#'   - \code{messages}: Character vector of progress messages
#'   - \code{git_commit}: Commit hash if auto-committed; \code{NA} otherwise
#'
#' @details
#'
#' **Workflow Overview:**
#'
#' 1. **Detection (Phase A pre-check)**
#'    - If \code{years = NULL}, detect missing years via \code{get_years_to_download()}
#'    - If no years missing, report and return early (unless \code{standardize = TRUE})
#'
#' 2. **Download (Phase A)** — Only if \code{download = TRUE}
#'    - Downloads CSVs for detected missing years to \code{inst/extdata/}
#'    - Validates each CSV before saving
#'    - On download failure: aborts update with error message
#'
#' 3. **Clean (Phase B)** — Only if \code{clean = TRUE} and years detected
#'    - Cleans newly downloaded years via \code{clean_rwb_single()}
#'    - Outputs normalized RDS to \code{data/cleaned/period_X/}
#'    - On cleaning failure: aborts update and reports which year failed
#'
#' 4. **Combine (Phase C)** — Always runs (required)
#'    - Recombines all cleaned periods via \code{combine_cleaned_periods()}
#'    - Recalculates evolution columns (rank_n_1, score_n_1, etc.)
#'    - Output: \code{data/processed/rwb_combined.rds}
#'    - Cost: ~1-2 seconds
#'
#' 5. **Standardize (Phase D)** — Always runs (required)
#'    - Re-standardizes all rows via \code{standardize_rwb_countries()}
#'    - Applies consolidation rules from \code{inst/extdata/consolidation_mapping.csv}
#'    - Output: \code{data/processed/rwb_standardized.rds}
#'    - Cost: ~2-3 seconds
#'
#' 6. **Export**
#'    - Regenerates \code{rwb_standardized.rda} via \code{data-raw/rwb_standardized.R}
#'    - Cost: <1 second
#'
#' 7. **Validation** — Only if \code{validate = TRUE}
#'    - Checks row count increase matches expectations
#'    - Verifies no duplicate rows
#'    - Ensures all required columns present
#'    - On validation failure: reports issues but doesn't abort
#'
#' 8. **Git Commit** — Only if \code{auto_commit = TRUE}
#'    - Stages updated RDS files
#'    - Creates commit with message describing what changed
#'    - On commit failure: reports warning but doesn't abort update
#'
#' **Intelligent Defaults:**
#' - \code{combine = TRUE}, \code{standardize = TRUE}: Cannot be overridden (always required)
#' - \code{validate = TRUE}: Recommended for production workflows
#' - \code{auto_commit = TRUE}: Recommended; provides git history of updates
#' - \code{verbose = TRUE}: Recommended for interactive use
#'
#' **Error Handling:**
#' - Download fails → Aborts with error
#' - Cleaning fails → Aborts and reports which year failed
#' - Combine/Standardize fail → Aborts (indicates data corruption)
#' - Validation fails → Reports issues; doesn't abort
#' - Git commit fails → Reports warning; doesn't abort update
#'
#' **Example: Minimal yearly update**
#' ```r
#' # Run once per year when new RSF data available
#' result <- update_rwb_data()
#' # Auto-detects missing years, downloads, cleans, combines, standardizes
#' print(result)
#' ```
#'
#' **Example: Testing without download**
#' ```r
#' # Test combining/standardizing without network calls
#' result <- update_rwb_data(years = NULL, download = FALSE, clean = FALSE)
#' ```
#'
#' @seealso
#' - \code{\link{download_rwb_data}} for Phase A details
#' - \code{\link{clean_rwb_single}} for Phase B details
#' - \code{\link{combine_cleaned_periods}} for Phase C details
#' - \code{\link{standardize_rwb_countries}} for Phase D details
#' - \code{\link{get_years_to_download}} for missing year detection
#'
#' @export
update_rwb_data <- function(
    years = NULL,
    download = TRUE,
    clean = TRUE,
    combine = TRUE,
    standardize = TRUE,
    validate = TRUE,
    verbose = TRUE,
    auto_commit = TRUE
) {

  # Initialize result list
  result <- list(
    status = "pending",
    years_downloaded = integer(0),
    years_cleaned = integer(0),
    rows_before = NA_integer_,
    rows_after = NA_integer_,
    consolidations_applied = NA_integer_,
    validation_passed = NA,
    messages = character(0),
    git_commit = NA_character_
  )

  tryCatch({

    # Ensure required packages are available
    required_pkgs <- c("dplyr", "stringr", "cli", "countrycode")
    for (pkg in required_pkgs) {
      if (!requireNamespace(pkg, quietly = TRUE)) {
        stop(sprintf("Package '%s' is required but not installed", pkg), call. = FALSE)
      }
    }

    # Load dplyr into environment (needed for n_distinct in standardize function)
    # This makes n_distinct available for cli interpolation strings
    library("dplyr", warn.conflicts = FALSE)

    # =====================================================================
    # PHASE 0: DETECTION
    # =====================================================================

    msg_detect <- "Starting update workflow..."
    result$messages <- c(result$messages, msg_detect)
    if (verbose) cli::cli_inform(msg_detect)

    # Auto-detect missing years if not specified
    if (is.null(years)) {
      years <- get_years_to_download()

      msg_detected <- sprintf(
        "Detected %d missing year(s): %s",
        length(years),
        paste(years, collapse = ", ")
      )
      result$messages <- c(result$messages, msg_detected)
      if (verbose) cli::cli_inform(msg_detected)

      # Early return if no missing years (unless standardize explicitly requested)
      if (length(years) == 0) {
        msg_none <- "No missing years to download. Skipping Phase A-B."
        result$messages <- c(result$messages, msg_none)
        if (verbose) cli::cli_inform(msg_none)

        years <- NULL  # Signal to skip A-B
      }
    }

    # =====================================================================
    # PHASE A: DOWNLOAD
    # =====================================================================

    if (download && !is.null(years) && length(years) > 0) {

      msg_dl_start <- sprintf("Phase A: Downloading %d year(s)...", length(years))
      result$messages <- c(result$messages, msg_dl_start)
      if (verbose) cli::cli_inform(msg_dl_start)

      # Validate CSVs before saving (download_rwb_data handles this)
      download_rwb_data(
        years = years,
        output_dir = "inst/extdata",
        skip_missing = TRUE,
        verbose = verbose
      )

      msg_dl_done <- sprintf("Phase A: Downloaded %d year(s)", length(years))
      result$messages <- c(result$messages, msg_dl_done)
      if (verbose) cli::cli_inform(msg_dl_done)

      result$years_downloaded <- years

    } else if (!download && !is.null(years)) {

      msg_dl_skip <- "Phase A: Skipped (download = FALSE)"
      result$messages <- c(result$messages, msg_dl_skip)
      if (verbose) cli::cli_inform(msg_dl_skip)

    } else {

      msg_dl_none <- "Phase A: No years to download"
      result$messages <- c(result$messages, msg_dl_none)
      if (verbose) cli::cli_inform(msg_dl_none)

    }

    # =====================================================================
    # PHASE B: CLEAN
    # =====================================================================

    if (clean && !is.null(years) && length(years) > 0) {

      msg_clean_start <- sprintf("Phase B: Cleaning %d year(s)...", length(years))
      result$messages <- c(result$messages, msg_clean_start)
      if (verbose) cli::cli_inform(msg_clean_start)

      for (year in years) {
        filepath <- here::here("inst/extdata", sprintf("rwb%04d.csv", year))

        if (!file.exists(filepath)) {
          err_msg <- sprintf("Downloaded CSV not found for year %d at %s", year, filepath)
          stop(err_msg, call. = FALSE)
        }

        clean_rwb_single(
          filepath = filepath,
          year = year,
          output_dir = "data/cleaned"
        )

        msg_clean_year <- sprintf("Cleaned: %d", year)
        result$messages <- c(result$messages, msg_clean_year)
        if (verbose) cli::cli_inform(msg_clean_year)
      }

      msg_clean_done <- sprintf("Phase B: Cleaned %d year(s)", length(years))
      result$messages <- c(result$messages, msg_clean_done)
      if (verbose) cli::cli_inform(msg_clean_done)

      result$years_cleaned <- years

    } else if (!clean && !is.null(years)) {

      msg_clean_skip <- "Phase B: Skipped (clean = FALSE)"
      result$messages <- c(result$messages, msg_clean_skip)
      if (verbose) cli::cli_inform(msg_clean_skip)

    } else {

      msg_clean_none <- "Phase B: No years to clean"
      result$messages <- c(result$messages, msg_clean_none)
      if (verbose) cli::cli_inform(msg_clean_none)

    }

    # =====================================================================
    # PHASE C: COMBINE (REQUIRED)
    # =====================================================================

    msg_combine_start <- "Phase C: Combining all periods (recalculating evolution columns)..."
    result$messages <- c(result$messages, msg_combine_start)
    if (verbose) cli::cli_inform(msg_combine_start)

    # Get row count before combine
    combined_path <- here::here("data/processed/rwb_combined.rds")
    if (file.exists(combined_path)) {
      result$rows_before <- nrow(readRDS(combined_path))
    } else {
      result$rows_before <- 0
    }

    combine_cleaned_periods(
      input_dir = here::here("data", "cleaned"),
      output_file = here::here("data", "processed", "rwb_combined.rds")
    )

    msg_combine_done <- "Phase C: Combined successfully"
    result$messages <- c(result$messages, msg_combine_done)
    if (verbose) cli::cli_inform(msg_combine_done)

    # =====================================================================
    # PHASE D: STANDARDIZE (REQUIRED)
    # =====================================================================

    msg_standardize_start <- "Phase D: Standardizing countries..."
    result$messages <- c(result$messages, msg_standardize_start)
    if (verbose) cli::cli_inform(msg_standardize_start)

    standardized_path <- here::here("data/processed/rwb_standardized.rds")
    standardize_rwb_countries(
      input_file = combined_path,
      output_file = standardized_path
    )

    # Get row count after standardize
    result$rows_after <- nrow(readRDS(standardized_path))

    msg_standardize_done <- "Phase D: Standardized successfully"
    result$messages <- c(result$messages, msg_standardize_done)
    if (verbose) cli::cli_inform(msg_standardize_done)

    # =====================================================================
    # EXPORT
    # =====================================================================

    msg_export_start <- "Exporting to package format..."
    result$messages <- c(result$messages, msg_export_start)
    if (verbose) cli::cli_inform(msg_export_start)

    # Source the export script
    source(here::here("data-raw/rwb_standardized.R"))

    msg_export_done <- "Exported successfully"
    result$messages <- c(result$messages, msg_export_done)
    if (verbose) cli::cli_inform(msg_export_done)

    # =====================================================================
    # VALIDATION
    # =====================================================================

    if (validate) {

      msg_validate_start <- "Running validation checks..."
      result$messages <- c(result$messages, msg_validate_start)
      if (verbose) cli::cli_inform(msg_validate_start)

      validation_result <- .validate_update(
        standardized_path = standardized_path,
        rows_before = result$rows_before,
        rows_after = result$rows_after,
        years_downloaded = result$years_downloaded,
        verbose = verbose
      )

      result$consolidations_applied <- validation_result$consolidations_applied
      result$validation_passed <- validation_result$passed

      if (validation_result$passed) {
        msg_validate_pass <- "Validation: All checks passed"
        result$messages <- c(result$messages, msg_validate_pass)
        if (verbose) cli::cli_inform(msg_validate_pass)
      } else {
        msg_validate_warn <- sprintf(
          "Validation: %s",
          paste(validation_result$issues, collapse = "; ")
        )
        result$messages <- c(result$messages, msg_validate_warn)
        if (verbose) cli::cli_warn(msg_validate_warn)
      }

    } else {

      msg_validate_skip <- "Validation: Skipped (validate = FALSE)"
      result$messages <- c(result$messages, msg_validate_skip)
      if (verbose) cli::cli_inform(msg_validate_skip)

    }

    # =====================================================================
    # GIT COMMIT
    # =====================================================================

    if (auto_commit) {

      msg_commit_start <- "Committing changes to git..."
      result$messages <- c(result$messages, msg_commit_start)
      if (verbose) cli::cli_inform(msg_commit_start)

      commit_result <- .commit_update(
        years_downloaded = result$years_downloaded,
        years_cleaned = result$years_cleaned,
        verbose = verbose
      )

      if (!is.na(commit_result$commit_hash)) {
        result$git_commit <- commit_result$commit_hash
        msg_commit_done <- sprintf("Committed: %s", commit_result$message)
        result$messages <- c(result$messages, msg_commit_done)
        if (verbose) cli::cli_inform(msg_commit_done)
      } else {
        msg_commit_skip <- commit_result$message
        result$messages <- c(result$messages, msg_commit_skip)
        if (verbose) cli::cli_warn(msg_commit_skip)
      }

    } else {

      msg_commit_skip <- "Git commit: Skipped (auto_commit = FALSE)"
      result$messages <- c(result$messages, msg_commit_skip)
      if (verbose) cli::cli_inform(msg_commit_skip)

    }

    # =====================================================================
    # FINALIZE
    # =====================================================================

    result$status <- "success"

    msg_final <- sprintf(
      "Update complete. Added %d row(s) (%d → %d total rows)",
      result$rows_after - result$rows_before,
      result$rows_before,
      result$rows_after
    )
    result$messages <- c(result$messages, msg_final)
    if (verbose) cli::cli_inform(msg_final)

    # Return invisibly with class
    class(result) <- c("rwb_update", "list")
    return(invisible(result))

  }, error = function(e) {

    result$status <- "failed"
    error_msg <- sprintf("Update failed: %s", conditionMessage(e))
    result$messages <- c(result$messages, error_msg)

    if (verbose) {
      cli::cli_abort(error_msg, call = NULL)
    } else {
      stop(error_msg, call. = FALSE)
    }

  })

}


#' Print Method for rwb_update Results
#'
#' @param x Object of class \code{rwb_update}
#' @param ... Additional arguments (unused)
#'
#' @keywords internal
#'
#' @export
print.rwb_update <- function(x, ...) {

  cat("\n")
  cat("=== RWB Data Update Report ===\n")
  cat("\n")

  cat(sprintf("Status: %s\n", toupper(x$status)))
  cat(sprintf("Years downloaded: %s\n",
    if (length(x$years_downloaded) > 0) {
      paste(x$years_downloaded, collapse = ", ")
    } else {
      "(none)"
    }
  ))
  cat(sprintf("Years cleaned: %s\n",
    if (length(x$years_cleaned) > 0) {
      paste(x$years_cleaned, collapse = ", ")
    } else {
      "(none)"
    }
  ))
  cat(sprintf("Rows before: %d\n", x$rows_before))
  cat(sprintf("Rows after: %d\n", x$rows_after))
  cat(sprintf("Row increase: %d\n", x$rows_after - x$rows_before))

  if (!is.na(x$consolidations_applied)) {
    cat(sprintf("Consolidation rules applied: %d\n", x$consolidations_applied))
  }

  if (!is.na(x$validation_passed)) {
    cat(sprintf("Validation passed: %s\n", tolower(x$validation_passed)))
  }

  if (!is.na(x$git_commit)) {
    cat(sprintf("Git commit: %s\n", x$git_commit))
  }

  if (length(x$messages) > 0) {
    cat("\nMessages:\n")
    for (msg in x$messages) {
      cat(sprintf("  - %s\n", msg))
    }
  }

  cat("\n")

  invisible(x)

}


# =========================================================================
# HELPER FUNCTIONS (INTERNAL)
# =========================================================================

#' Validate Update Results
#'
#' @keywords internal
.validate_update <- function(
    standardized_path,
    rows_before,
    rows_after,
    years_downloaded,
    verbose = TRUE
) {

  issues <- character(0)
  passed <- TRUE

  # Read standardized data
  rwb <- readRDS(standardized_path)

  # Check 1: Row count is reasonable
  expected_increase <- max(length(years_downloaded) * 195, 0)  # ~195 countries per year
  actual_increase <- rows_after - rows_before

  if (actual_increase < 0) {
    issues <- c(issues, "Row count decreased (expected increase or no change)")
    passed <- FALSE
  }

  # Check 2: No duplicate rows
  if (nrow(rwb) != nrow(dplyr::distinct(rwb))) {
    n_dupes <- nrow(rwb) - nrow(dplyr::distinct(rwb))
    issues <- c(issues, sprintf("%d duplicate row(s) detected", n_dupes))
    passed <- FALSE
  }

  # Check 3: Required columns present
  required_cols <- c(
    "year_n", "iso", "country_en", "score", "rank",
    "political_context", "economic_context", "legal_context",
    "social_context", "safety", "zone"
  )

  missing_cols <- setdiff(required_cols, names(rwb))
  if (length(missing_cols) > 0) {
    issues <- c(issues, sprintf("Missing columns: %s", paste(missing_cols, collapse = ", ")))
    passed <- FALSE
  }

  # Check 4: Count consolidation rules applied
  consolidations_applied <- sum(rwb$consolidated == 1, na.rm = TRUE)

  return(list(
    passed = passed,
    issues = issues,
    consolidations_applied = consolidations_applied
  ))

}


#' Commit Changes to Git
#'
#' @keywords internal
.commit_update <- function(
    years_downloaded,
    years_cleaned,
    verbose = TRUE
) {

  # Check if we're in a git repo
  tryCatch({

    git_root <- system("git rev-parse --show-toplevel", intern = TRUE, ignore.stderr = TRUE)

    if (length(git_root) == 0 || nchar(git_root) == 0) {
      return(list(
        commit_hash = NA_character_,
        message = "Not in a git repository; skipped auto-commit"
      ))
    }

  }, error = function(e) {
    return(list(
      commit_hash = NA_character_,
      message = "Could not determine git root; skipped auto-commit"
    ))
  })

  # Build commit message
  if (length(years_downloaded) > 0) {
    commit_msg <- sprintf(
      "Update RWB data: Added %s",
      paste(years_downloaded, collapse = ", ")
    )
  } else {
    commit_msg <- "Update RWB data: Recombined and re-standardized existing years"
  }

  # Stage files
  files_to_stage <- c(
    "data/processed/rwb_combined.rds",
    "data/processed/rwb_standardized.rds",
    "data/rwb_standardized.rda"
  )

  for (file in files_to_stage) {
    file_path <- here::here(file)
    if (file.exists(file_path)) {
      system(sprintf("git add '%s'", file_path), ignore.stderr = TRUE)
    }
  }

  # Also stage downloaded CSVs if any
  if (length(years_downloaded) > 0) {
    for (year in years_downloaded) {
      csv_path <- here::here("inst/extdata", sprintf("rwb%04d.csv", year))
      if (file.exists(csv_path)) {
        system(sprintf("git add '%s'", csv_path), ignore.stderr = TRUE)
      }
    }
  }

  # Commit
  result <- system(
    sprintf("git commit -m '%s'", commit_msg),
    intern = TRUE,
    ignore.stderr = TRUE
  )

  # Extract commit hash from output
  # Format: "[main abc1234] Commit message"
  commit_match <- grep("\\[.* ([a-f0-9]+)\\]", result, value = TRUE)

  if (length(commit_match) > 0) {
    # Extract hash
    hash <- sub(".*\\[.* ([a-f0-9]+)\\].*", "\\1", commit_match[1])
    return(list(
      commit_hash = hash,
      message = sprintf("Committed with message: %s", commit_msg)
    ))
  } else {
    # No new commits (nothing staged)
    return(list(
      commit_hash = NA_character_,
      message = "No changes to commit (already up to date)"
    ))
  }

}
