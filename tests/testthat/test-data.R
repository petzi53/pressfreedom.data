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
