# Test suite for R/utils.R
# Covers pure/cheap helper functions used throughout the cleaning pipeline

test_that("get_period classifies years into the correct period", {
  expect_equal(get_period(2002), "period_1")
  expect_equal(get_period(2012), "period_1")
  expect_equal(get_period(2013), "period_2")
  expect_equal(get_period(2021), "period_2")
  expect_equal(get_period(2022), "period_3")
  expect_equal(get_period(2026), "period_3")
})

test_that("get_period returns NA for 2011 (no official RSF data)", {
  expect_true(is.na(get_period(2011)))
})

test_that("get_period returns NA outside the known range", {
  expect_true(is.na(get_period(2001)))
  expect_true(is.na(get_period(2027)))
})

test_that("get_period_encoding maps periods to the expected (deprecated) encodings", {
  expect_equal(get_period_encoding(2005), "ISO-8859-1")
  expect_equal(get_period_encoding(2015), "ISO-8859-1")
  expect_equal(get_period_encoding(2024), "UTF-8")
  expect_true(is.na(get_period_encoding(2011)))
})

test_that("get_years_to_download returns all years when input_dir doesn't exist", {
  result <- get_years_to_download(
    input_dir = fs::path_temp("does-not-exist-12345"),
    all_years = 2020:2023
  )
  expect_equal(result, c(2020, 2021, 2022, 2023))
})

test_that("get_years_to_download excludes 2011 even if in all_years", {
  result <- get_years_to_download(
    input_dir = fs::path_temp("does-not-exist-12345"),
    all_years = 2010:2012
  )
  expect_false(2011 %in% result)
})

test_that("get_years_to_download detects existing files and returns only missing years", {
  temp_dir <- fs::path_temp("rwb-test-years")
  fs::dir_create(temp_dir)
  on.exit(fs::dir_delete(temp_dir))

  fs::file_create(fs::path(temp_dir, c("rwb2020.csv", "rwb2022.csv")))

  result <- get_years_to_download(input_dir = temp_dir, all_years = 2020:2023)
  expect_equal(sort(result), c(2021, 2023))
})

test_that("get_years_to_download returns empty vector when nothing is missing", {
  temp_dir <- fs::path_temp("rwb-test-years-complete")
  fs::dir_create(temp_dir)
  on.exit(fs::dir_delete(temp_dir))

  fs::file_create(fs::path(temp_dir, c("rwb2020.csv", "rwb2021.csv")))

  result <- get_years_to_download(input_dir = temp_dir, all_years = 2020:2021)
  expect_length(result, 0)
})

test_that("standardize_decimal_separators converts comma to period", {
  df <- tibble::tibble(score = c("82,50", "71,00"), other = c("x", "y"))
  result <- standardize_decimal_separators(df, "score")

  expect_equal(result$score, c("82.50", "71.00"))
  expect_equal(result$other, c("x", "y"))
})

test_that("standardize_decimal_separators leaves values without commas unchanged", {
  df <- tibble::tibble(score = c("82.50", "71.00"))
  result <- standardize_decimal_separators(df, "score")
  expect_equal(result$score, c("82.50", "71.00"))
})

test_that("standardize_decimal_separators handles multiple columns", {
  df <- tibble::tibble(a = "1,5", b = "2,5")
  result <- standardize_decimal_separators(df, c("a", "b"))
  expect_equal(result$a, "1.5")
  expect_equal(result$b, "2.5")
})

test_that("convert_factors_to_character converts factor columns to character", {
  df <- tibble::tibble(iso = factor("FRA"), zone = factor("Europe"), n = 1)
  result <- convert_factors_to_character(df, c("iso", "zone"))

  expect_type(result$iso, "character")
  expect_type(result$zone, "character")
  expect_equal(result$iso, "FRA")
  expect_true(is.numeric(result$n))
})

test_that("detect_score_column finds year-specific column name first", {
  df <- tibble::tibble("Score 2026" = 75, "Score" = 70)
  expect_equal(detect_score_column(df, 2026), "Score 2026")
})

test_that("detect_score_column falls back to generic 'Score'", {
  df <- tibble::tibble("Score" = 70)
  expect_equal(detect_score_column(df, 2024), "Score")
})

test_that("detect_score_column returns NA if neither column is found", {
  df <- tibble::tibble(other = 1)
  expect_true(is.na(detect_score_column(df, 2024)))
})

test_that("normalize_column_names renames and reorders Period 1 columns", {
  df <- tibble::tibble(
    "Year (N)" = 2005,
    "ISO" = "FRA",
    "EN_country" = "France",
    "Score N" = "82.50",
    "Rank N" = "1",
    "Zone" = "Europe",
    "Rank N-1" = "2",
    "Rank evolution" = "1",
    "Score N-1" = "81.75"
  )

  result <- normalize_column_names(df, period = "1", year = 2005, mapping = period_1_mapping)

  expect_equal(names(result), target_columns)
  expect_equal(result$country_en, "France")
  expect_true(is.na(result$political_context))
})

test_that("normalize_column_names detects the year-specific score column for Period 3", {
  df <- tibble::tibble(
    "Year (N)" = 2026,
    "ISO" = "DEU",
    "Country_EN" = "Germany",
    "Score 2026" = 75,
    "Rank" = 8,
    "Political Context" = 60,
    "Rank_Pol" = 10,
    "Economic Context" = 70,
    "Rank_Eco" = 8,
    "Legal Context" = 80,
    "Rank_Leg" = 7,
    "Social Context" = 75,
    "Rank_Soc" = 9,
    "Safety" = 85,
    "Rank_Saf" = 6,
    "Zone" = "Europe",
    "Rank N-1" = 9,
    "Rank evolution" = -1,
    "Score N-1" = 74,
    "Score evolution" = 0.7
  )

  result <- normalize_column_names(df, period = "3", year = 2026, mapping = period_3_mapping)

  expect_equal(names(result), target_columns)
  expect_equal(result$score, 75)
})
