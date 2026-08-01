# Test suite for data cleaning functions (Plan B1)
# Tests column name normalization, data type conversion, and output structure

library(testthat)

# Helper: Create mock Period 1 data
create_mock_period_1 <- function(year = 2005) {
  tibble::tibble(
    "Year (N)" = year,
    "ISO" = "FRA",
    "EN_country" = "France",
    "Rank N" = "1",
    "Score N" = "82,50",
    "Rank N-1" = "2",
    "Score N-1" = "81,75",
    "Rank evolution" = "1",
    "Zone" = "Europe",
    "FR_country" = "France",  # Extra language column to drop
    "ES_country" = "Francia"   # Extra language column to drop
  )
}

# Helper: Create mock Period 3 data (2023+ with score history)
#
# "Score", "Score N-1", and the five dimension columns are raw digit strings
# with an implied 2-decimal scaling (e.g. "7550" means 75.50), matching RSF's
# real export format (see inst/extdata/rwb2025.csv) and
# resolve_percent_scaling(). clean_period_3() runs score_n_1 through
# resolve_percent_scaling() the same way as score (fixed in commit 87b4f35 --
# see also test-data.R for a regression test on the shipped dataset).
create_mock_period_3_recent <- function(year = 2023) {
  tibble::tibble(
    "Year (N)" = year,
    "ISO" = "DEU",
    "Country_EN" = "Germany",
    "Rank" = "8",
    "Score" = "7550",
    "Political Context" = "6010",
    "Rank_Pol" = "10",
    "Economic Context" = "7020",
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
}

# Helper: Create mock Period 3 data (2022 without score history)
# See create_mock_period_3_recent() for the raw-digit-scaling rationale.
create_mock_period_3_2022 <- function() {
  tibble::tibble(
    "Year (N)" = 2022,
    "ISO" = "DEU",
    "Country_EN" = "Germany",
    "Rank" = "8",
    "Score" = "7550",
    "Political Context" = "6010",
    "Rank_Pol" = "10",
    "Economic Context" = "7020",
    "Rank_Eco" = "8",
    "Legal Context" = "8030",
    "Rank_Leg" = "7",
    "Social Context" = "7540",
    "Rank_Soc" = "9",
    "Safety" = "8550",
    "Rank_Saf" = "6",
    "Zone" = "Europe",
    "Rank N-1" = NA_real_,
    "Rank evolution" = NA_real_,
    "Score N-1" = NA_real_,
    "Score evolution" = NA_real_
  )
}

# Helper: Create mock Period 3 data with year-specific score name
create_mock_period_3_year_score <- function(year = 2025) {
  # Build tibble with dynamic column name
  score_col_name <- glue::glue("Score {year}")
  df <- tibble::tibble(
    "Year (N)" = year,
    "ISO" = "ITA",
    "Country_EN" = "Italy",
    "Rank" = "10",
    "Political Context" = "58.1",
    "Rank_Pol" = "12",
    "Economic Context" = "68.2",
    "Rank_Eco" = "10",
    "Legal Context" = "78.3",
    "Rank_Leg" = "9",
    "Social Context" = "73.4",
    "Rank_Soc" = "11",
    "Safety" = "83.5",
    "Rank_Saf" = "8",
    "Zone" = "Europe",
    "Rank N-1" = "11",
    "Rank evolution" = "1",
    "Score N-1" = "7250",
    "Score evolution" = "0.7"
  )
  # Add the year-specific score column. RSF's real exports store this as a
  # raw digit string with an implied 2-decimal scaling (e.g. "7320" means
  # 73.20), not a string with a literal decimal point -- see
  # resolve_percent_scaling() and inst/extdata/rwb2025.csv.
  df[[score_col_name]] <- "7320"
  df
}

# ============================================================================
# Test: Column Mappings
# ============================================================================

test_that("period_1_mapping has correct structure", {
  expect_type(period_1_mapping, "list")
  expect_length(period_1_mapping, 20)
  expect_named(period_1_mapping)
  expect_identical(names(period_1_mapping), target_columns)
})

test_that("period_2_mapping is identical to period_1_mapping", {
  expect_identical(period_2_mapping, period_1_mapping)
})

test_that("period_3_mapping has correct structure", {
  expect_type(period_3_mapping, "list")
  expect_length(period_3_mapping, 20)
  expect_named(period_3_mapping)
  expect_identical(names(period_3_mapping), target_columns)
})

test_that("target_columns has correct length and order", {
  expect_length(target_columns, 20)
  expected_order <- c(
    "year_n", "iso", "country_en", "score", "rank",
    "political_context", "rank_pol", "economic_context", "rank_eco",
    "legal_context", "rank_leg", "social_context", "rank_soc",
    "safety", "rank_saf", "zone", "rank_n_1", "rank_evolution",
    "score_n_1", "score_evolution"
  )
  expect_identical(target_columns, expected_order)
})

# ============================================================================
# Test: Utility Functions
# ============================================================================

test_that("detect_score_column finds generic 'Score'", {
  df <- create_mock_period_3_recent()
  result <- detect_score_column(df, 2023)
  expect_equal(result, "Score")
})

test_that("detect_score_column finds year-specific score name", {
  df <- create_mock_period_3_year_score(2025)
  result <- detect_score_column(df, 2025)
  expect_equal(result, "Score 2025")
})

test_that("detect_score_column returns NA when score not found", {
  df <- tibble::tibble(x = 1, y = 2)
  result <- detect_score_column(df, 2023)
  expect_true(is.na(result))
})

test_that("standardize_decimal_separators converts comma to period", {
  df <- tibble::tibble(
    value = c("82,50", "81,75", "80,25")
  )
  result <- standardize_decimal_separators(df, "value")
  expect_equal(result$value, c("82.50", "81.75", "80.25"))
})

test_that("convert_factors_to_character converts factors", {
  df <- tibble::tibble(
    iso = factor("FRA"),
    country = factor("France")
  )
  result <- convert_factors_to_character(df, c("iso", "country"))
  expect_type(result$iso, "character")
  expect_type(result$country, "character")
  expect_equal(result$iso, "FRA")
  expect_equal(result$country, "France")
})

# ============================================================================
# Test: Column Name Normalization
# ============================================================================

test_that("normalize_column_names applies Period 1 mapping", {
  df <- create_mock_period_1(2005)
  result <- normalize_column_names(df, "1", 2005, period_1_mapping)

  # Check output has 20 columns in correct order
  expect_equal(ncol(result), 20)
  expect_identical(names(result), target_columns)

  # Check renamed columns
  expect_equal(result$year_n, 2005)
  expect_equal(result$iso, "FRA")
  expect_equal(result$country_en, "France")
})

test_that("normalize_column_names adds NA columns for Period 1", {
  df <- create_mock_period_1(2005)
  result <- normalize_column_names(df, "1", 2005, period_1_mapping)

  # Dimension columns should be NA
  expect_true(all(is.na(result$political_context)))
  expect_true(all(is.na(result$rank_pol)))
  expect_true(all(is.na(result$score_evolution)))
})

test_that("normalize_column_names detects year-specific score for Period 3", {
  df <- create_mock_period_3_year_score(2026)
  mapping <- get_period_mapping("3", 2026)
  result <- normalize_column_names(df, "3", 2026, mapping)

  expect_equal(ncol(result), 20)
  expect_identical(names(result), target_columns)
})

# ============================================================================
# Test: Period 1 Cleaning
# ============================================================================

test_that("clean_period_1 produces correct structure", {
  # Create temporary test file
  df <- create_mock_period_1(2005)
  temp_file <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_file, delim = ";")

  result <- clean_period_1(temp_file, 2005)

  # Check structure
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 20)
  expect_identical(names(result), target_columns)

  # Check data types
  expect_type(result$iso, "character")
  expect_type(result$country_en, "character")
  expect_type(result$score, "double")
  expect_type(result$rank, "double")

  # Clean up
  unlink(temp_file)
})

test_that("clean_period_1 converts decimal separators", {
  df <- create_mock_period_1(2005)
  temp_file <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_file, delim = ";")

  result <- clean_period_1(temp_file, 2005)

  # Scores should be converted from comma to period
  expect_equal(result$score, 82.50)
  expect_equal(result$score_n_1, 81.75)

  unlink(temp_file)
})

# ============================================================================
# Test: Period 3 Cleaning
# ============================================================================

test_that("clean_period_3 produces correct structure", {
  df <- create_mock_period_3_recent(2023)
  temp_file <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_file, delim = ";")

  result <- clean_period_3(temp_file, 2023)

  expect_equal(ncol(result), 20)
  expect_identical(names(result), target_columns)
  expect_type(result$iso, "character")
  expect_type(result$political_context, "double")
  expect_equal(result$score, 75.50)
  expect_equal(result$political_context, 60.10)
  expect_equal(result$economic_context, 70.20)
  expect_equal(result$legal_context, 80.30)
  expect_equal(result$social_context, 75.40)
  expect_equal(result$safety, 85.50)
  expect_equal(result$score_n_1, 74.80)

  unlink(temp_file)
})

test_that("clean_period_3 handles year-specific score names", {
  df <- create_mock_period_3_year_score(2025)
  temp_file <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_file, delim = ";")

  result <- clean_period_3(temp_file, 2025)

  expect_equal(ncol(result), 20)
  expect_equal(result$score, 73.20)
  expect_equal(result$score_n_1, 72.50)

  unlink(temp_file)
})

test_that("clean_period_3 sets score history to NA for 2022", {
  df <- create_mock_period_3_2022()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_file, delim = ";")

  result <- clean_period_3(temp_file, 2022)

  # Score history should be NA
  expect_true(is.na(result$score_n_1))
  expect_true(is.na(result$score_evolution))

  unlink(temp_file)
})

# ============================================================================
# Test: Single Year Cleaning Dispatcher
# ============================================================================

test_that("clean_rwb_single creates RDS file with correct name", {
  df <- create_mock_period_1(2005)
  temp_input <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_input, delim = ";")

  temp_output_dir <- tempdir()

  output_path <- clean_rwb_single(temp_input, 2005, temp_output_dir)

  expect_true(file.exists(output_path))
  expect_match(basename(output_path), "rwb2005_cleaned\\.rds")

  # Verify RDS content
  loaded <- readr::read_rds(output_path)
  expect_equal(ncol(loaded), 20)
  expect_identical(names(loaded), target_columns)

  unlink(temp_input)
  unlink(output_path)
})

test_that("clean_rwb_single validates output structure", {
  # Create data with wrong number of columns
  df <- tibble::tibble(x = 1, y = 2)
  temp_input <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_input, delim = ";")

  temp_output_dir <- tempdir()

  # Should error - either due to validation or missing columns
  expect_error(clean_rwb_single(temp_input, 2005, temp_output_dir), NA)

  unlink(temp_input)
})

test_that("clean_rwb_single rejects invalid year", {
  df <- create_mock_period_1(2005)
  temp_input <- tempfile(fileext = ".csv")
  readr::write_delim(df, temp_input, delim = ";")

  temp_output_dir <- tempdir()

  expect_error(
    clean_rwb_single(temp_input, 2011, temp_output_dir),
    "Cannot determine period"
  )

  unlink(temp_input)
})
