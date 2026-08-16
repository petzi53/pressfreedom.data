# Test suite for column name validation and override safety net
# (see R/column_validation.R and inst/extdata/period3_column_overrides.csv)

library(testthat)

# ============================================================================
# Test: validate_column_names_exist()
# ============================================================================

test_that("validate_column_names_exist passes silently when all columns present", {
  df <- tibble::tibble(ISO = "FRA", Score = "8550", Rank = "1")
  expect_no_error(
    validate_column_names_exist(df, c("ISO", "Score", "Rank"), 2025)
  )
})

test_that("validate_column_names_exist aborts with clear message when a column is missing", {
  df <- tibble::tibble(ISO = "FRA", Economy = "7020", Rank = "1")

  expect_error(
    validate_column_names_exist(df, c("ISO", "Economic Context", "Rank"), 2027),
    "Economic Context"
  )
})

test_that("validate_column_names_exist error message lists available columns", {
  df <- tibble::tibble(ISO = "FRA", Economy = "7020")

  err <- rlang::catch_cnd(
    validate_column_names_exist(df, c("Economic Context"), 2027)
  )
  expect_match(conditionMessage(err), "Economy")
  expect_match(conditionMessage(err), "2027")
})


# ============================================================================
# Test: load_column_overrides()
# ============================================================================

test_that("load_column_overrides returns NULL when file does not exist", {
  result <- load_column_overrides(2027, overrides_file = "does/not/exist.csv")
  expect_null(result)
})

test_that("load_column_overrides returns NULL when file has no rows for the year", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  readr::write_csv(
    tibble::tibble(
      year = 2025, target_col = "score",
      expected_col = "Score", actual_col = "Score 2025", note = "demo"
    ),
    tmp
  )

  result <- load_column_overrides(2027, overrides_file = tmp)
  expect_null(result)
})

test_that("load_column_overrides returns a named list for a matching year", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  readr::write_csv(
    tibble::tibble(
      year = 2025, target_col = "score",
      expected_col = "Score", actual_col = "Score 2025", note = "demo"
    ),
    tmp
  )

  result <- load_column_overrides(2025, overrides_file = tmp)
  expect_equal(result, list(score = "Score 2025"))
})

test_that("load_column_overrides reads the shipped Score override for 2025", {
  # Exercises the real inst/extdata/period3_column_overrides.csv shipped
  # with the package: RSF renamed "Score" to "Score 2025" starting that
  # year, resolved here via the general override mechanism (not a
  # dedicated detection function -- see period_3_mapping's docs)
  result <- load_column_overrides(2025)
  expect_equal(result, list(score = "Score 2025"))
})

test_that("load_column_overrides reads the shipped Score override for 2026", {
  result <- load_column_overrides(2026)
  expect_equal(result, list(score = "Score 2026"))
})


# ============================================================================
# Test: apply_column_overrides()
# ============================================================================

test_that("apply_column_overrides updates matching target columns", {
  mapping <- list(score = NA, economic_context = "Economic Context")
  overrides <- list(economic_context = "Economy")

  result <- apply_column_overrides(mapping, overrides)
  expect_equal(result$economic_context, "Economy")
  expect_true(is.na(result$score))
})

test_that("apply_column_overrides returns mapping unchanged when overrides is NULL", {
  mapping <- list(score = "Score", economic_context = "Economic Context")
  result <- apply_column_overrides(mapping, NULL)
  expect_equal(result, mapping)
})

test_that("apply_column_overrides warns and ignores unknown target columns", {
  mapping <- list(score = "Score")
  overrides <- list(nonexistent_col = "Something")

  expect_warning(
    result <- apply_column_overrides(mapping, overrides),
    "nonexistent_col"
  )
  expect_equal(result, mapping)
})


# ============================================================================
# Test: End-to-end safety net via clean_period_3()
# ============================================================================

test_that("clean_period_3 aborts with a clear error for an unmapped renamed column", {
  # Simulate RSF renaming "Economic Context" to "Economy" with no override
  # on file -- should fail loud, not produce a silent all-NA column
  df <- tibble::tibble(
    "Year (N)" = 2027,
    "ISO" = "DEU",
    "Country_EN" = "Germany",
    "Rank" = "8",
    "Score" = "7550",
    "Political Context" = "6010",
    "Rank_Pol" = "10",
    "Economy" = "7020", # renamed from "Economic Context"
    "Rank_Eco" = "8",
    "Legal Context" = "8030",
    "Rank_Leg" = "7",
    "Social Context" = "7540",
    "Rank_Soc" = "9",
    "Safety" = "8550",
    "Rank_Saf" = "6",
    "Zone" = "Europe",
    "Rank N-1" = "9",
    "Rank evolution" = "-1",
    "Score N-1" = "7480",
    "Score evolution" = "0.7"
  )

  tmp_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp_csv), add = TRUE)
  readr::write_delim(df, tmp_csv, delim = ";")

  expect_error(
    clean_period_3(tmp_csv, 2027),
    "Economic Context"
  )
})

test_that("clean_period_3 succeeds for a renamed column when an override is applied", {
  # Same renamed-column scenario, but resolved via apply_column_overrides()
  # directly against the mapping (demonstrates the fix without requiring
  # a temporary overrides CSV on disk). Mock data mirrors
  # create_mock_period_3_recent() in test-clean.R, with "Economic Context"
  # renamed to "Economy" (test files run in isolated environments, so the
  # shared helper there isn't reused here).
  df <- tibble::tibble(
    "Year (N)" = 2027,
    "ISO" = "DEU",
    "Country_EN" = "Germany",
    "Rank" = "8",
    "Score" = "7550",
    "Political Context" = "6010",
    "Rank_Pol" = "10",
    "Economy" = "7020", # renamed from "Economic Context"
    "Rank_Eco" = "8",
    "Legal Context" = "8030",
    "Rank_Leg" = "7",
    "Social Context" = "7540",
    "Rank_Soc" = "9",
    "Safety" = "8550",
    "Rank_Saf" = "6",
    "Zone" = "Europe",
    "Rank N-1" = "9",
    "Rank evolution" = "-1",
    "Score N-1" = "7480",
    "Score evolution" = "0.7"
  )

  mapping <- get_period_mapping("3", 2027)
  mapping <- apply_column_overrides(mapping, list(economic_context = "Economy"))

  expected_raw_cols <- unique(unlist(mapping)[!is.na(unlist(mapping))])
  expect_no_error(validate_column_names_exist(df, expected_raw_cols, 2027))

  result <- normalize_column_names(df, "3", 2027, mapping)
  expect_false(all(is.na(result$economic_context)))
})
