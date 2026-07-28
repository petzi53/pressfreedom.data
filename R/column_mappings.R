# Column name mappings for Period 1–3 data
# Maps raw column names to unified 20-column output structure

#' Column Mapping for Period 1 (2002–2012)
#' @description
#' Period 1 raw columns mapped to unified 20-column structure.
#' Periods 1–2 omit dimension columns and score history columns (set as NA).
#' Named in target column order.
#'
#' @keywords internal
period_1_mapping <- list(
  year_n = "Year (N)",
  iso = "ISO",
  country_en = "EN_country",
  score = "Score N",
  rank = "Rank N",
  political_context = NA,
  rank_pol = NA,
  economic_context = NA,
  rank_eco = NA,
  legal_context = NA,
  rank_leg = NA,
  social_context = NA,
  rank_soc = NA,
  safety = NA,
  rank_saf = NA,
  zone = "Zone",
  rank_n_1 = "Rank N-1",
  rank_evolution = "Rank evolution",
  score_n_1 = "Score N-1",
  score_evolution = NA
)

#' Column Mapping for Period 2 (2013–2021)
#' @description
#' Period 2 raw columns mapped to unified 20-column structure.
#' Identical to Period 1 except methodology changed in 2013 (scores comparable).
#'
#' @keywords internal
period_2_mapping <- period_1_mapping

#' Column Mapping for Period 3 (2022–2026)
#' @description
#' Period 3 raw columns mapped to unified 20-column structure.
#' Note: Score column names vary by year (Score, Score 2022, etc.)
#' This mapping handles the generic case; score column detected separately.
#' Named in target column order.
#'
#' @keywords internal
period_3_mapping <- list(
  year_n = "Year (N)",
  iso = "ISO",
  country_en = "Country_EN",
  score = NA,  # Detected separately (Score, Score 2022, etc.)
  rank = "Rank",
  political_context = "Political Context",
  rank_pol = "Rank_Pol",
  economic_context = "Economic Context",
  rank_eco = "Rank_Eco",
  legal_context = "Legal Context",
  rank_leg = "Rank_Leg",
  social_context = "Social Context",
  rank_soc = "Rank_Soc",
  safety = "Safety",
  rank_saf = "Rank_Saf",
  zone = "Zone",
  rank_n_1 = "Rank N-1",
  rank_evolution = "Rank evolution",
  score_n_1 = "Score N-1",
  score_evolution = "Score evolution"
)

#' Target output structure (20 columns in order)
#' @description
#' Defines the unified output structure for all periods.
#'
#' @keywords internal
target_columns <- c(
  "year_n",
  "iso",
  "country_en",
  "score",
  "rank",
  "political_context",
  "rank_pol",
  "economic_context",
  "rank_eco",
  "legal_context",
  "rank_leg",
  "social_context",
  "rank_soc",
  "safety",
  "rank_saf",
  "zone",
  "rank_n_1",
  "rank_evolution",
  "score_n_1",
  "score_evolution"
)

#' Get the appropriate mapping for a given period and year
#' @param period Character: "1", "2", or "3"
#' @param year Numeric: year of data
#' @return List with column mappings
#' @keywords internal
get_period_mapping <- function(period, year) {
  switch(period,
    "1" = period_1_mapping,
    "2" = period_2_mapping,
    "3" = period_3_mapping,
    cli::cli_abort("Unknown period: {period}")
  )
}
