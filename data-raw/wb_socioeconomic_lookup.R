# Step 1.6: Build socioeconomic lookup files (population, GDP, area)
#
# Reads:
#   - WB population.csv (annual, 2002–2024)
#   - WB gdp.csv (annual, 2002–2023)
#   - UNSD SYB68 population-surface-area.csv (area only)
#
# Produces:
#   - inst/extdata/wb_population.csv (population_mn, annual with forward-fill to 2026)
#   - inst/extdata/wb_gdp.csv (gdp_usd_mn, annual with forward-fill to 2026)
#   - inst/extdata/unsd_syb_area.csv (area_km2, static)
#
# Forward-fill strategy:
#   - Population: 2024 → 2025–2026
#   - GDP: 2023 → 2024–2026
#
# Bad-parse rows in WB files (e.g., "St. Kitts and Nevis") affect countries
# not in rwb_standardized; no recovery logic needed.

rsf_years <- c(2002:2010, 2012:2026)
rsf_isos  <- unique(readRDS(
  here::here("data", "processed", "rwb_standardized.rds"))$iso)

# ── 1. World Bank population ──────────────────────────────────────────────────
wb_pop_raw <- readr::read_csv(
  here::here("data-raw", "source", "wb", "population.csv"),
  col_types = readr::cols(.default = readr::col_character())
)

wb_population <- wb_pop_raw |>
  dplyr::filter(grepl("^[A-Z]{3}$", .data$`Country Code`)) |>
  dplyr::filter(.data$`Country Code` %in% rsf_isos) |>
  dplyr::mutate(
    iso           = .data$`Country Code`,
    year          = as.integer(.data$Year),
    population_mn = as.numeric(.data$Value) / 1e6
  ) |>
  dplyr::filter(!is.na(.data$year), !is.na(.data$population_mn)) |>
  dplyr::select("iso", "year", "population_mn")

# Forward-fill 2025 and 2026 from 2024
pop_2024 <- wb_population |>
  dplyr::filter(.data$year == 2024) |>
  dplyr::select("iso", "population_mn")

wb_population <- dplyr::bind_rows(
  wb_population,
  pop_2024 |> dplyr::mutate(year = 2025L),
  pop_2024 |> dplyr::mutate(year = 2026L)
) |>
  dplyr::filter(.data$year %in% rsf_years) |>
  dplyr::arrange(.data$iso, .data$year)

readr::write_csv(wb_population,
                 here::here("inst", "extdata", "wb_population.csv"))

# ── 2. World Bank GDP ─────────────────────────────────────────────────────────
wb_gdp_raw <- readr::read_csv(
  here::here("data-raw", "source", "wb", "gdp.csv"),
  col_types = readr::cols(.default = readr::col_character())
)

wb_gdp <- wb_gdp_raw |>
  dplyr::filter(grepl("^[A-Z]{3}$", .data$`Country Code`)) |>
  dplyr::filter(.data$`Country Code` %in% rsf_isos) |>
  dplyr::mutate(
    iso        = .data$`Country Code`,
    year       = as.integer(.data$Year),
    gdp_usd_mn = as.numeric(.data$Value) / 1e6
  ) |>
  dplyr::filter(!is.na(.data$year), !is.na(.data$gdp_usd_mn)) |>
  dplyr::select("iso", "year", "gdp_usd_mn")

# Forward-fill 2024, 2025, 2026 from 2023
gdp_2023 <- wb_gdp |>
  dplyr::filter(.data$year == 2023) |>
  dplyr::select("iso", "gdp_usd_mn")

wb_gdp <- dplyr::bind_rows(
  wb_gdp,
  gdp_2023 |> dplyr::mutate(year = 2024L),
  gdp_2023 |> dplyr::mutate(year = 2025L),
  gdp_2023 |> dplyr::mutate(year = 2026L)
) |>
  dplyr::filter(.data$year %in% rsf_years) |>
  dplyr::arrange(.data$iso, .data$year)

readr::write_csv(wb_gdp, here::here("inst", "extdata", "wb_gdp.csv"))

# ── 3. UNSD SYB surface area (static) ────────────────────────────────────────
pop_valid_years <- c("2010", "2015", "2023", "2025")

syb_pop_raw <- readr::read_csv(
  here::here("data-raw", "source", "un",
             "syb68-population-surface-area.csv"),
  skip      = 2,
  col_names = c("m49_code", "region_name", "year", "series", "value",
                "footnotes", "source", "x8", "x9", "x10", "x11"),
  col_types = readr::cols(.default = readr::col_character()),
  locale    = readr::locale(encoding = "latin1")
)

# M49 -> ISO-3 (strip leading zeros)
m49_iso <- readr::read_csv2(
  here::here("data-raw", "source", "un", "unsd-methodology.csv"),
  col_types = readr::cols(.default = readr::col_character()),
  locale    = readr::locale(encoding = "UTF-8")
) |>
  dplyr::select(m49_code = `M49 Code`, iso = `ISO-alpha3 Code`) |>
  dplyr::mutate(m49_code = as.character(as.integer(.data$m49_code))) |>
  dplyr::filter(!is.na(.data$iso), .data$iso != "")

area_df <- syb_pop_raw |>
  dplyr::filter(
    .data$year %in% pop_valid_years,
    stringr::str_starts(.data$series, "Surface area"),
    # Use a single reference year (values identical across snapshot years)
    .data$year == "2023"
  ) |>
  dplyr::inner_join(m49_iso, by = "m49_code") |>
  dplyr::filter(.data$iso %in% rsf_isos) |>
  dplyr::mutate(
    # SYB unit is thousand km2; convert to km2
    area_km2 = as.numeric(stringr::str_replace(.data$value, ",", ".")) * 1000
  ) |>
  dplyr::select("iso", "area_km2") |>
  dplyr::arrange(.data$iso)

readr::write_csv(area_df, here::here("inst", "extdata", "unsd_syb_area.csv"))

# ── 4. Coverage report ────────────────────────────────────────────────────────
missing_pop  <- rsf_isos[!rsf_isos %in% wb_population$iso]
missing_gdp  <- rsf_isos[!rsf_isos %in% wb_gdp$iso]
missing_area <- rsf_isos[!rsf_isos %in% area_df$iso]
message("Missing population: ", paste(missing_pop,  collapse = ", "))
message("Missing GDP:        ", paste(missing_gdp,  collapse = ", "))
message("Missing area:       ", paste(missing_area, collapse = ", "))
# Expected: population 6, GDP 7 (adds PRK), area ~6
