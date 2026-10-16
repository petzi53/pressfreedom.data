# Regression tests for the shipped rwb_standardized dataset
#
# score_n_1 for 2023-2026 was, for a period, cleaned in clean_period_3()
# without resolve_percent_scaling() (see comment history in R/clean.R),
# leaving values ~100x too large relative to score/score_evolution (fixed in
# commit 87b4f35). These tests guard against that regression re-appearing.

test_that("score_n_1 is on the same 0-100 scale as score for 2023-2026", {
  recent <- rwb_standardized[rwb_standardized$year_n %in% 2023:2026, ]
  has_history <- !is.na(recent$score_n_1)

  # 2023-2026 should always carry prior-year history
  expect_true(all(has_history))

  expect_true(all(recent$score_n_1[has_history] >= 0))
  expect_true(all(recent$score_n_1[has_history] <= 100))
})

test_that("score_n_1 plus score_evolution reconstructs score for 2023-2026", {
  recent <- rwb_standardized[rwb_standardized$year_n %in% 2023:2026, ]

  reconstructed <- recent$score_n_1 + recent$score_evolution
  # Small tolerance for RSF's own rounding of score_evolution
  expect_equal(reconstructed, recent$score, tolerance = 0.01)
})

# Regression tests for the UN/World Bank classification and socioeconomic
# columns added in the 2026-09-13 "add-un-wb-columns" plan (Phase 5).
# `iso` codes YUG, SCG, CXX, XXX are known, documented gaps (historical
# entities / non-UN territories absent from the UNSD and WB source files);
# they are deliberately excluded from "no NA" assertions below rather than
# silently passed, per R/data.R documentation.

# ---- Column presence and count ---------------------------------------------

test_that("column count is 51", {
  expect_equal(ncol(rwb_standardized), 51L)
})

test_that("all new classification columns present", {
  new_cols <- c(
    "UN", "un_region", "un_subregion", "un_intermediate_region", "LDC", "LLDC", "SIDS",
    "wb_region", "wb_region2", "wb_region2_code", "wb_lending_category",
    "arab_world", "euro_area", "central_europe_baltics", "small_states",
    "fragile_state", "HIPC", "IDA_only", "IDA_blend", "IDA_IBRD_total",
    "IBRD_only", "IDA_total", "wb_income_group", "middle_income", "low_middle_income",
    "population_mn", "area_km2", "gdp_usd_mn", "gdp_pc_usd"
  )
  expect_true(all(new_cols %in% names(rwb_standardized)))
})

# ---- Types -------------------------------------------------------------------

test_that("logical columns are logical", {
  logi_cols <- c(
    "UN", "LDC", "LLDC", "SIDS", "arab_world", "euro_area",
    "central_europe_baltics", "small_states", "fragile_state",
    "HIPC", "IDA_only", "IDA_blend", "IDA_IBRD_total", "IBRD_only",
    "IDA_total", "middle_income", "low_middle_income"
  )
  for (col in logi_cols) {
    expect_type(rwb_standardized[[col]], "logical")
  }
})

test_that("character columns are character", {
  char_cols <- c(
    "un_region", "un_subregion", "un_intermediate_region",
    "wb_region", "wb_region2", "wb_region2_code",
    "wb_lending_category", "wb_income_group"
  )
  for (col in char_cols) {
    expect_type(rwb_standardized[[col]], "character")
  }
})

test_that("numeric columns are double", {
  expect_type(rwb_standardized$population_mn, "double")
  expect_type(rwb_standardized$area_km2, "double")
  expect_type(rwb_standardized$gdp_usd_mn, "double")
  expect_type(rwb_standardized$gdp_pc_usd, "double")
})

# ---- UN membership -------------------------------------------------------------

test_that("UN: known members and non-members", {
  expect_true(rwb_standardized[rwb_standardized$iso == "USA" &
    rwb_standardized$year_n == 2010, "UN"][[1]])
  expect_false(rwb_standardized[rwb_standardized$iso == "PSE" &
    rwb_standardized$year_n == 2010, "UN"][[1]])
  expect_false(rwb_standardized[rwb_standardized$iso == "TWN" &
    rwb_standardized$year_n == 2010, "UN"][[1]])
  # MNE does not appear in rwb_standardized before 2007 (recorded as part of
  # Serbia and Montenegro / SCG until then), so the pre-accession FALSE
  # branch of add_un_timevary_column() can't be exercised via a real row;
  # confirm the post-accession TRUE value instead.
  expect_true(rwb_standardized[rwb_standardized$iso == "MNE" &
    rwb_standardized$year_n == 2007, "UN"][[1]])
})

# ---- M49 regions ---------------------------------------------------------------

test_that("un_region has no NAs outside documented gap ISOs", {
  known_gap_isos <- c("YUG", "SCG", "CXX", "XXX")
  rows_to_check <- rwb_standardized[!rwb_standardized$iso %in% known_gap_isos, ]
  expect_equal(sum(is.na(rows_to_check$un_region)), 0L)
})

test_that("un_intermediate_region has no NAs among rows with a matched un_region", {
  matched <- rwb_standardized[!is.na(rwb_standardized$un_region), ]
  expect_equal(sum(is.na(matched$un_intermediate_region)), 0L)
})

# ---- LDC -------------------------------------------------------------------

test_that("LDC: known values and time variation", {
  expect_false(any(rwb_standardized[rwb_standardized$iso == "DEU", "LDC"][[1]],
    na.rm = TRUE
  ))
  # At least one country should have changed LDC status (graduation)
  ldc_change <- rwb_standardized |>
    dplyr::group_by(.data$iso) |>
    dplyr::summarise(
      n_vals = dplyr::n_distinct(.data$LDC, na.rm = TRUE),
      .groups = "drop"
    )
  expect_true(any(ldc_change$n_vals > 1))
})

# ---- euro_area ---------------------------------------------------------------

test_that("euro_area: time-varying accession", {
  expect_true(rwb_standardized[rwb_standardized$iso == "DEU" &
    rwb_standardized$year_n == 2005, "euro_area"][[1]])
  expect_false(rwb_standardized[rwb_standardized$iso == "USA" &
    rwb_standardized$year_n == 2010, "euro_area"][[1]])
  expect_false(rwb_standardized[rwb_standardized$iso == "HRV" &
    rwb_standardized$year_n == 2022, "euro_area"][[1]])
  expect_true(rwb_standardized[rwb_standardized$iso == "HRV" &
    rwb_standardized$year_n == 2023, "euro_area"][[1]])
})

# ---- fragile_state -------------------------------------------------------------

test_that("fragile_state: known values and NA pre-2006", {
  expect_true(rwb_standardized[rwb_standardized$iso == "AFG" &
    rwb_standardized$year_n == 2006, "fragile_state"][[1]])
  expect_false(rwb_standardized[rwb_standardized$iso == "DEU" &
    rwb_standardized$year_n == 2006, "fragile_state"][[1]])
  # IBRD-only country: should be TRUE from the MD source (not missing, as
  # in the old composition CSV). 2011 is absent from RSF entirely, so the
  # first year IRQ's FCS listing (effective FY2011) actually shows up is 2012.
  expect_true(rwb_standardized[rwb_standardized$iso == "IRQ" &
    rwb_standardized$year_n == 2012, "fragile_state"][[1]])
  # Pre-FCS years must be NA, not FALSE
  expect_true(is.na(rwb_standardized[rwb_standardized$iso == "USA" &
    rwb_standardized$year_n == 2003, "fragile_state"][[1]]))
})

# ---- HIPC --------------------------------------------------------------------

test_that("HIPC: completion point transitions", {
  expect_false(rwb_standardized[rwb_standardized$iso == "GHA" &
    rwb_standardized$year_n == 2003, "HIPC"][[1]])
  expect_true(rwb_standardized[rwb_standardized$iso == "GHA" &
    rwb_standardized$year_n == 2004, "HIPC"][[1]])
  expect_false(rwb_standardized[rwb_standardized$iso == "TCD" &
    rwb_standardized$year_n == 2014, "HIPC"][[1]])
  expect_true(rwb_standardized[rwb_standardized$iso == "TCD" &
    rwb_standardized$year_n == 2015, "HIPC"][[1]])
  expect_false(any(rwb_standardized[rwb_standardized$iso == "DEU", "HIPC"][[1]]))
})

# ---- WB static -----------------------------------------------------------------

test_that("wb_region2_code: Sub-Saharan Africa is AFE or AFW", {
  ssa_rows <- rwb_standardized[!is.na(rwb_standardized$wb_region) &
    rwb_standardized$wb_region == "Sub-Saharan Africa", ]
  expect_true(all(ssa_rows$wb_region2_code %in% c("AFE", "AFW")))
})

test_that("small_states: Mauritius is TRUE", {
  # Antigua and Barbuda (ATG), the plan's original example, is not covered
  # by RSF at all, so it has zero rows in rwb_standardized and can't be used
  # to check a join result. Mauritius is both small_states == TRUE in the
  # WB CLASS composition and present in rwb_standardized.
  expect_true(any(rwb_standardized[rwb_standardized$iso == "MUS", "small_states"][[1]]))
})

test_that("central_europe_baltics: known values", {
  expect_true(any(rwb_standardized[
    rwb_standardized$iso == "POL",
    "central_europe_baltics"
  ][[1]]))
  expect_false(any(rwb_standardized[
    rwb_standardized$iso == "FRA",
    "central_europe_baltics"
  ][[1]]))
})

# ---- WB time-varying -----------------------------------------------------------

test_that("wb_income_group: non-NA for USA; NA for CXX", {
  expect_false(any(is.na(rwb_standardized[
    rwb_standardized$iso == "USA",
    "wb_income_group"
  ][[1]])))
  expect_true(all(is.na(rwb_standardized[
    rwb_standardized$iso == "CXX",
    "wb_income_group"
  ][[1]])))
})

test_that("middle_income and low_middle_income logic", {
  expect_false(any(rwb_standardized[rwb_standardized$iso == "DEU", "middle_income"][[1]]))
  expect_false(any(rwb_standardized[
    rwb_standardized$iso == "DEU",
    "low_middle_income"
  ][[1]]))
})

# ---- Socioeconomic ---------------------------------------------------------------

test_that("population_mn is positive where non-NA", {
  vals <- rwb_standardized$population_mn[!is.na(rwb_standardized$population_mn)]
  expect_true(all(vals > 0))
})

test_that("area_km2 is static per country", {
  area_check <- rwb_standardized |>
    dplyr::group_by(.data$iso) |>
    dplyr::summarise(
      n_vals = dplyr::n_distinct(.data$area_km2, na.rm = TRUE),
      .groups = "drop"
    )
  expect_true(all(area_check$n_vals <= 1))
})

test_that("known NA ISOs have NA population", {
  na_isos <- c("CXX", "XXK", "XXX", "YUG", "SCG", "TWN")
  for (iso_code in na_isos) {
    rows <- rwb_standardized[rwb_standardized$iso == iso_code, ]
    if (nrow(rows) > 0) {
      expect_true(all(is.na(rows$population_mn)),
        label = paste("population_mn NA for", iso_code)
      )
    }
  }
})

test_that("gdp_pc_usd is NA when either component is NA", {
  expect_true(all(is.na(rwb_standardized[
    rwb_standardized$iso == "PRK",
    "gdp_pc_usd"
  ][[1]])))
})
