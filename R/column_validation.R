#' Validate That Expected Raw Columns Exist in a CSV
#'
#' Fails loudly if any expected raw column name is missing from the data
#' frame, rather than letting downstream renaming silently produce all-NA
#' columns. Intended to be called right after reading a raw CSV and
#' resolving the column mapping (including any overrides), before any
#' renaming happens.
#'
#' @param df Data frame. The raw CSV, read with all columns as character.
#' @param expected_raw_cols Character vector. Raw column names the mapping
#'   expects to find in `df`.
#' @param year Numeric. Year of the data (for the error message).
#'
#' @return Invisible `NULL`. Called for its side effect (aborting on
#'   failure).
#'
#' @details
#' This exists because RSF has renamed export columns before without notice
#' (e.g. "Score" -> "Score 2025") and may rename others in the future in
#' ways that cannot be predicted ahead of time (e.g. "Economic Context" ->
#' "Economy"). Without this check, a renamed column silently resolves to
#' `NA` for every row via `normalize_column_names()`, and the corrupted
#' data can ship undetected. See `load_column_overrides()` for how to fix
#' a failure this raises without changing package code.
#'
#' @keywords internal
validate_column_names_exist <- function(df, expected_raw_cols, year) {
  missing_cols <- setdiff(expected_raw_cols, names(df))

  if (length(missing_cols) > 0) {
    available_cols <- paste(sort(names(df)), collapse = ", ")
    missing_str <- paste(missing_cols, collapse = ", ")

    cli::cli_abort(c(
      "Year {year}: expected column(s) not found in raw CSV.",
      "x" = "Missing: {missing_str}",
      "i" = "Available columns: {available_cols}",
      "i" = paste(
        "RSF may have renamed a column. Add a row to",
        "inst/extdata/period3_column_overrides.csv (columns: year,",
        "target_col, expected_col, actual_col) to fix this without",
        "changing package code."
      )
    ))
  }

  invisible(NULL)
}


#' Load User-Provided Column Name Overrides
#'
#' Reads `period3_column_overrides.csv`, if present, and returns any
#' override mappings for the given year as a named list suitable for
#' `apply_column_overrides()`.
#'
#' @param year Numeric. Year to look up overrides for.
#' @param overrides_file Character. Path to the overrides CSV. Defaults to
#'   the file shipped in `inst/extdata/` via `system.file()`.
#'
#' @return Named list (`target_col = "actual_col"`, ...) of overrides for
#'   `year`, or `NULL` if the file doesn't exist or has no rows for `year`.
#'
#' @details
#' This is the general-purpose safety net for RSF column renames -- both
#' the ones already seen (e.g. `"Score"` -> `"Score 2025"`) and any future,
#' unpredictable ones (e.g. `"Economic Context"` -> `"Economy"`). There is
#' no special-cased detection logic for any single column, including
#' `score`: every rename, however likely, is handled the same way, via
#' this override file. When `validate_column_names_exist()` aborts because
#' an expected column is missing, add a row to the CSV:
#'
#' ```
#' year,target_col,expected_col,actual_col
#' 2027,economic_context,Economic Context,Economy
#' ```
#'
#' `target_col` is the unified output column name (from `target_columns`);
#' `expected_col` documents what the mapping originally expected (for human
#' readability only, not used programmatically); `actual_col` is the raw
#' column name actually found in that year's CSV. Append future rows to the
#' same file rather than creating a new file per year.
#'
#' @keywords internal
load_column_overrides <- function(year, overrides_file = NULL) {
  if (is.null(overrides_file)) {
    overrides_file <- system.file(
      "extdata", "period3_column_overrides.csv",
      package = "pressfreedom.data"
    )
  }

  if (!nzchar(overrides_file) || !file.exists(overrides_file)) {
    return(NULL)
  }

  overrides_df <- readr::read_csv(
    overrides_file,
    col_types = readr::cols(
      year = readr::col_double(),
      target_col = readr::col_character(),
      expected_col = readr::col_character(),
      actual_col = readr::col_character(),
      .default = readr::col_character()
    ),
    show_col_types = FALSE
  )

  year_overrides <- overrides_df |>
    dplyr::filter(.data$year == !!year)

  if (nrow(year_overrides) == 0) {
    return(NULL)
  }

  rlang::set_names(year_overrides$actual_col, year_overrides$target_col) |>
    as.list()
}


#' Apply Column Name Overrides to a Mapping
#'
#' Updates a period column mapping (target_col -> raw_col) with
#' user-provided overrides, so a renamed raw column can still be found.
#'
#' @param mapping List. Period column mapping, as returned by
#'   `get_period_mapping()`.
#' @param overrides Named list as returned by `load_column_overrides()`
#'   (`target_col = "actual_col"`), or `NULL`.
#'
#' @return The (possibly updated) mapping list.
#'
#' @keywords internal
apply_column_overrides <- function(mapping, overrides) {
  if (is.null(overrides) || length(overrides) == 0) {
    return(mapping)
  }

  for (target_col in names(overrides)) {
    if (target_col %in% names(mapping)) {
      mapping[[target_col]] <- overrides[[target_col]]
    } else {
      cli::cli_warn(
        "Override target column {.val {target_col}} not found in mapping; ignoring."
      )
    }
  }

  mapping
}
