# Build inst/extdata/fcs_history.csv: time-varying World Bank fragile/
# conflict-affected status by iso x year_n
#
# Source: data-raw/source/fcs/fcs_supplement_all_years.csv, a hand-transcribed
# supplement (iso, year_n) covering every country listed on any WB FY2006-
# FY2026 fragility list (LICUS / Fragile States / Harmonized List / FCS List).
# Transcribed from data-raw/source/fcs/C2-FCSList-FY06toFY26.md because the
# existing fcs-list-for-ddh_0-Data.csv systematically excludes IBRD-only
# (higher-income) countries that still appear on the WB FCS list (e.g. IRQ,
# LBY, LBN) -- see AGENTS.md for the methodology history (LICUS -> Fragile
# States -> Harmonized List -> FCS List, FY2006-FY2026).
#
# All severity tiers (Severe/Core/Marginal, conflict/institutional, etc.)
# within a year are collapsed to a single TRUE; absence from the supplement
# for a given iso x year_n means fragile_state = FALSE (post-join). RSF years
# 2002-2005 predate the WB list entirely and are left out of the output grid,
# so add_fcs_timevary_column() must leave those as NA, not FALSE.

# 2011 is intentionally missing from the RSF data
rsf_years <- c(2002:2010, 2012:2026)

fcs_supplement <- readr::read_csv(
  here::here("data-raw", "source", "fcs", "fcs_supplement_all_years.csv"),
  col_types = readr::cols(
    iso    = readr::col_character(),
    year_n = readr::col_integer()
  )
) |>
  dplyr::mutate(fragile_state = TRUE) |>
  dplyr::distinct()

stopifnot(
  !anyDuplicated(fcs_supplement[c("iso", "year_n")])
)

# Full country x year grid for FY2006-FY2026 (WB fiscal year FY20XX -> RSF
# year_n = 20XX); countries absent from a given year's supplement rows are
# not fragile that year -> FALSE after the left join
fcs_history <- tidyr::expand_grid(
  iso    = unique(fcs_supplement$iso),
  year_n = 2006:2026
) |>
  dplyr::left_join(fcs_supplement, by = c("iso", "year_n")) |>
  dplyr::mutate(
    fragile_state = dplyr::coalesce(.data$fragile_state, FALSE)
  ) |>
  dplyr::filter(.data$year_n %in% rsf_years) |>   # drop 2011
  dplyr::arrange(.data$iso, .data$year_n)

readr::write_csv(fcs_history, here::here("inst", "extdata", "fcs_history.csv"))
