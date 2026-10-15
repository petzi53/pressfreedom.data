# Build inst/extdata/m49_lookup.csv from the UNSD methodology CSV.
#
# Columns: iso, un_region, un_subregion, un_intermediate_region, LLDC, SIDS.
# `UN` (member-state status) is NOT in this lookup -- it is time-varying and
# handled separately via an inline tribble (see R/add_classifications.R).

# library(readr)
# library(dplyr)
# library(here)

unsd_raw <- readr::read_csv2(
  here::here("data-raw", "source", "un", "unsd-methodology.csv"),
  locale = readr::locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

# Phase 0 (Step 0.1) found the UNSD CSV is missing XKX (Kosovo) and TWN
# (Taiwan) relative to the sibling repo's m49_ext6.rds, because neither is a
# UN member state and UNSD's methodology table only covers members/observers.
# SCQ (Sark) is also missing from the UNSD CSV but never appears in
# rwb_standardized, so it needs no manual row. Values for Kosovo/TWN below
# are taken from m49_ext6.rds (Region/Sub-region/Intermediate Region all
# match; neither is LLDC nor SIDS).
#
# NOTE: rwb_standardized stores Kosovo's ISO code as "XXK", not the raw RSF/
# ISO-ish "XKX" -- R/standardize.R remaps country_en == "Kosovo" to "XXK"
# during consolidation. The manual row below uses "XXK" so it actually joins;
# using "XKX" here would silently produce NA for Kosovo.
manual_rows <- tibble::tribble(
  ~iso,  ~un_region, ~un_subregion,     ~un_intermediate_region, ~LLDC, ~SIDS,
  "XXK", "Europe",   "Southern Europe", "Southern Europe",       FALSE, FALSE,
  "TWN", "Asia",     "Eastern Asia",    "Eastern Asia",          FALSE, FALSE
)

lookup_m49 <- unsd_raw |>
  dplyr::filter(!is.na(.data$`ISO-alpha3 Code`)) |>
  dplyr::select(
    iso                    = "ISO-alpha3 Code",
    un_region              = "Region Name",
    un_subregion           = "Sub-region Name",
    un_intermediate_region = "Intermediate Region Name",
    LLDC = "Land Locked Developing Countries (LLDC)",
    SIDS = "Small Island Developing States (SIDS)"
  ) |>
  dplyr::mutate(
    # Channel Islands (Guernsey dependencies) have no Intermediate Region in
    # the source; fall back to Sub-region for everyone else missing one.
    un_intermediate_region = dplyr::case_when(
      .data$iso %in% c("GGY", "JEY") ~ "Northern Europe",
      is.na(.data$un_intermediate_region) ~ .data$un_subregion,
      TRUE ~ .data$un_intermediate_region
    ),
    LLDC = !is.na(.data$LLDC) & .data$LLDC == "x",
    SIDS = !is.na(.data$SIDS) & .data$SIDS == "x"
  ) |>
  # ATA (Antarctica) has no region/sub-region in the source and never
  # appears in rwb_standardized; drop rather than fabricate a region.
  dplyr::filter(!is.na(.data$un_region)) |>
  dplyr::select(
    "iso", "un_region", "un_subregion", "un_intermediate_region", "LLDC", "SIDS"
  ) |>
  dplyr::bind_rows(manual_rows)

stopifnot(sum(is.na(lookup_m49$un_intermediate_region)) == 0)
stopifnot(!anyDuplicated(lookup_m49$iso))

readr::write_csv(lookup_m49, here::here("inst", "extdata", "m49_lookup.csv"))
