# Reads World Bank CLASS files -> inst/extdata/wb_static_lookup.csv
# euro_area, fragile_state, and HIPC are NOT derived here -- all three are
# time-varying and implemented as inline tribbles or external CSVs in Phase 2
# (R/add_classifications.R).

class_path <- here::here("data-raw", "source", "class")

# rwb_standardized stores Kosovo's ISO code as "XXK" (R/standardize.R remaps
# country_en == "Kosovo" to "XXK" during consolidation), but the WB CLASS
# files use "XKX" -- the same Kosovo gotcha already documented for
# fcs_history.R and m49_lookup.R. Remapped at ingestion in both source files
# below so Kosovo's WB data actually joins instead of silently becoming NA.

# ---- Part A: wb_region and wb_lending_category -----------------------------
list_econ <- readr::read_csv(
  file.path(class_path, "CLASS_2026_07_15-List of economies.csv"),
  show_col_types = FALSE
) |>
  # Group/aggregate rows (AFE, ARB, CSS, ...) share the 3-char code length
  # with real ISO-3 codes, so Region (NA only for aggregates) is the
  # reliable filter; nchar() is kept as a belt-and-suspenders check.
  dplyr::filter(nchar(.data$Code) == 3, !is.na(.data$Region)) |>
  dplyr::mutate(Code = dplyr::if_else(.data$Code == "XKX", "XXK", .data$Code)) |>
  dplyr::select(
    iso                 = "Code",
    wb_region           = "Region",
    wb_lending_category = "Lending category"
  ) |>
  dplyr::mutate(
    wb_lending_category = dplyr::na_if(.data$wb_lending_category, "")
  )

# ---- Part B: Group membership flags from composition -----------------------
composition <- readr::read_csv(
  file.path(class_path, "CLASS_2026_07_15-composition.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(
    WB_Country_Code = dplyr::if_else(
      .data$WB_Country_Code == "XKX", "XXK", .data$WB_Country_Code
    )
  )

# NOTE: as of the 2026-07-15 CLASS vintage, WB merged Afghanistan and
# Pakistan into the MENA region; the live Region string is
# "Middle East, North Africa, Afghanistan & Pakistan" (not the shorter
# "Middle East & North Africa" originally anticipated in the plan). South
# Asia dropped from 8 to 6 countries as a result. Code kept as "MNA".
wb_region_code_map <- c(
  "East Asia & Pacific"                                 = "EAS",
  "Europe & Central Asia"                                = "ECS",
  "Latin America & Caribbean"                            = "LCN",
  "Middle East, North Africa, Afghanistan & Pakistan"    = "MNA",
  "North America"                                        = "NAC",
  "South Asia"                                           = "SAS"
  # Sub-Saharan Africa: replaced by AFE/AFW below
)

# EMU (euro_area), FCS (fragile_state), HPC (HIPC) intentionally omitted --
# these are now time-varying columns handled outside this script.
group_map <- c(
  AFE = "afe", AFW = "afw",
  ARB = "arab_world",
  CEB = "central_europe_baltics",
  SST = "small_states",
  IBT = "IDA_IBRD_total",
  IDA = "IDA_total"
)

group_flags <- purrr::imap(
  group_map,
  \(col_name, code) {
    composition |>
      dplyr::filter(.data$WB_Group_Code == code) |>
      dplyr::transmute(iso = .data$WB_Country_Code, !!col_name := TRUE)
  }
) |>
  purrr::reduce(\(x, y) dplyr::full_join(x, y, by = "iso"))

# ---- Part C: Combine and derive remaining columns ---------------------------
wb_static <- list_econ |>
  dplyr::left_join(group_flags, by = "iso") |>
  dplyr::mutate(
    dplyr::across(
      c("arab_world", "central_europe_baltics", "small_states",
        "IDA_IBRD_total", "IDA_total", "afe", "afw"),
      \(x) dplyr::coalesce(x, FALSE)
    ),
    wb_region2 = dplyr::case_when(
      .data$afe ~ "Eastern and Southern Africa",
      .data$afw ~ "Western and Central Africa",
      TRUE ~ .data$wb_region
    ),
    wb_region2_code = dplyr::case_when(
      .data$afe ~ "AFE",
      .data$afw ~ "AFW",
      TRUE ~ wb_region_code_map[.data$wb_region]
    ),
    IDA_only  = dplyr::coalesce(.data$wb_lending_category == "IDA",  FALSE),
    IDA_blend = dplyr::coalesce(.data$wb_lending_category == "Blend", FALSE),
    IBRD_only = dplyr::coalesce(.data$wb_lending_category == "IBRD", FALSE)
  ) |>
  dplyr::select(
    "iso", "wb_region", "wb_region2", "wb_region2_code", "wb_lending_category",
    "arab_world", "central_europe_baltics", "small_states",
    "IDA_IBRD_total", "IDA_total", "IDA_only", "IDA_blend", "IBRD_only"
  )

stopifnot(sum(is.na(wb_static$wb_region2_code)) == 0)

readr::write_csv(wb_static, here::here("inst", "extdata", "wb_static_lookup.csv"))
