# Test suite for R/standardize.R
# Country-name consolidation is the recurring failure mode in this project
# (see AGENTS.md), so this file focuses on the consolidation engine,
# mojibake repair, and the output validator.

# Helper: minimal combined_df fixture with the columns
# consolidate_and_standardize_countries() actually touches (year_n,
# country_en, zone), plus a couple of downstream columns used elsewhere.
make_combined_df <- function(...) {
  defaults <- list(
    year_n = 2020,
    country_en = "France",
    zone = "EU & Balkans",
    score = 80,
    rank = 10
  )
  overrides <- list(...)
  tibble::as_tibble(utils::modifyList(defaults, overrides))
}

test_that("repair_and_asciify leaves plain ASCII strings unchanged", {
  expect_equal(repair_and_asciify("France"), "France")
  expect_equal(repair_and_asciify(c("France", "Germany")), c("France", "Germany"))
})

test_that("repair_and_asciify transliterates accented characters to ASCII", {
  expect_equal(repair_and_asciify("C\u00f4te d'Ivoire"), "Cote d'Ivoire")
})

test_that("repair_and_asciify reverses single-pass mojibake corruption", {
  # "caf\u00c3\u00a9" is the string "caf\u00e9" ("cafe" with an accent) after
  # its UTF-8 bytes were misread as Latin-1 -- the classic RSF artifact.
  expect_equal(repair_and_asciify("caf\u00c3\u00a9"), "cafe")
})

test_that("repair_and_asciify passes through NA", {
  expect_true(is.na(repair_and_asciify(NA_character_)))
})

test_that("consolidate_and_standardize_countries deletes Israel/US territorial rows", {
  df <- make_combined_df(country_en = "Israel (occupied territories)")
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  result <- consolidate_and_standardize_countries(df, mapping)

  expect_equal(nrow(result), 0)
})

test_that("consolidate_and_standardize_countries merges Israel variants into one row", {
  df <- dplyr::bind_rows(
    make_combined_df(country_en = "Israel (Israeli territory)"),
    make_combined_df(country_en = "Israel (outside Israeli territory)")
  )
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  result <- consolidate_and_standardize_countries(df, mapping)

  expect_equal(nrow(result), 1)
  expect_equal(result$country_en, "Israel")
  expect_true(result$consolidation_flag)
})

test_that("consolidate_and_standardize_countries applies name-mapping consolidations", {
  df <- make_combined_df(country_en = "Czech Republic")
  mapping <- tibble::tibble(
    old_name = "Czech Republic",
    new_name = "Czechia",
    iso_code = "CZE",
    reason = "Official name change"
  )

  result <- consolidate_and_standardize_countries(df, mapping)

  expect_equal(result$country_en, "Czechia")
  expect_true(result$consolidation_flag)
  expect_equal(result$iso, "CZE")
})

test_that("consolidate_and_standardize_countries leaves unmapped countries unflagged", {
  df <- make_combined_df(country_en = "France")
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  result <- consolidate_and_standardize_countries(df, mapping)

  expect_equal(result$country_en, "France")
  expect_false(result$consolidation_flag)
  expect_equal(result$iso, "FRA")
})

test_that("consolidate_and_standardize_countries translates zone labels to English", {
  df <- make_combined_df(zone = "Afrique")
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  result <- consolidate_and_standardize_countries(df, mapping)

  expect_equal(result$zone, "Africa")
})

test_that("consolidate_and_standardize_countries aborts on an unrecognized zone value", {
  df <- make_combined_df(zone = "Not A Real Zone")
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  expect_error(
    consolidate_and_standardize_countries(df, mapping),
    class = "rlang_error"
  )
})

test_that("consolidate_and_standardize_countries remaps the 2022 zone anomaly", {
  df <- dplyr::bind_rows(
    make_combined_df(year_n = 2020, country_en = "Egypt", zone = "MENA"),
    make_combined_df(year_n = 2022, country_en = "Egypt", zone = "Maghreb - Moyen-Orient")
  )
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  result <- consolidate_and_standardize_countries(df, mapping)
  row_2022 <- result[result$year_n == 2022, ]

  expect_equal(row_2022$zone, "Middle East & North Africa")
})

test_that("consolidate_and_standardize_countries assigns hardcoded ISO overrides", {
  df <- make_combined_df(country_en = "Northern Cyprus")
  mapping <- tibble::tibble(old_name = character(), new_name = character())

  result <- consolidate_and_standardize_countries(df, mapping)

  expect_equal(result$iso, "CXX")
})

test_that("validate_standardization passes for clean, complete data", {
  standardized <- tibble::tibble(
    year_n = 2020,
    iso = "FRA",
    country_en = "France",
    score = 80,
    rank = 10,
    country_name_original = "France",
    consolidation_flag = FALSE
  )

  expect_true(validate_standardization(standardized, original_row_count = 1))
})

test_that("validate_standardization flags missing ISO codes", {
  standardized <- tibble::tibble(
    year_n = 2020,
    iso = NA_character_,
    country_en = "Atlantis",
    score = 80,
    rank = 10,
    country_name_original = "Atlantis",
    consolidation_flag = FALSE
  )

  expect_warning(
    result <- validate_standardization(standardized, original_row_count = 1)
  )
  expect_false(result)
})

test_that("validate_standardization flags duplicate year/country pairs", {
  standardized <- tibble::tibble(
    year_n = c(2020, 2020),
    iso = c("FRA", "FRA"),
    country_en = c("France", "France"),
    score = c(80, 81),
    rank = c(10, 11),
    country_name_original = c("France", "France"),
    consolidation_flag = c(FALSE, FALSE)
  )

  expect_warning(
    result <- validate_standardization(standardized, original_row_count = 2)
  )
  expect_false(result)
})

test_that("validate_standardization flags an increase in row count", {
  standardized <- tibble::tibble(
    year_n = c(2020, 2021),
    iso = c("FRA", "DEU"),
    country_en = c("France", "Germany"),
    score = c(80, 75),
    rank = c(10, 12),
    country_name_original = c("France", "Germany"),
    consolidation_flag = c(FALSE, FALSE)
  )

  expect_warning(
    result <- validate_standardization(standardized, original_row_count = 1)
  )
  expect_false(result)
})
