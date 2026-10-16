# World Bank income group history (OGHIST)
#
# Reads OGHIST CSV → inst/extdata/wb_income_history.csv
# Structure: Rows 1–4 are metadata; row 5 is fiscal year codes (FY89–FY27);
# row 6 is calendar years.
#
# Income codes: L = "Low income", LM = "Lower middle income",
# UM = "Upper middle income", H = "High income", .. = NA

oghist_path <- here::here(
  "data-raw", "source", "oghist",
  "OGHIST_2026_07_15-Country Analytical History.csv"
)

raw <- readr::read_csv(oghist_path, skip = 4, col_names = FALSE,
                       show_col_types = FALSE)

fy_header  <- as.character(raw[1, ])
data_rows  <- raw[-(1:2), ]
col_names  <- c("iso", "country_name", fy_header[-(1:2)])
names(data_rows) <- col_names

rsf_years  <- setdiff(2002:2026, 2011)
fy_columns <- stringr::str_c("FY", stringr::str_sub(as.character(rsf_years), 3, 4))

income_code_map <- c(
  L  = "Low income",
  LM = "Lower middle income",
  UM = "Upper middle income",
  H  = "High income"
)

wb_income_history <- data_rows |>
  dplyr::filter(nchar(.data$iso) == 3) |>
  dplyr::select("iso", dplyr::all_of(fy_columns)) |>
  tidyr::pivot_longer(
    cols      = -"iso",
    names_to  = "fy",
    values_to = "code"
  ) |>
  dplyr::mutate(
    year_n = 2000L + as.integer(stringr::str_sub(.data$fy, 3, 4)),
    year_n = dplyr::if_else(.data$year_n < 1990L, .data$year_n + 100L, .data$year_n),
    wb_income_group = dplyr::recode(.data$code, !!!income_code_map,
                                    .default = NA_character_)
  ) |>
  dplyr::select("iso", "year_n", "wb_income_group")

readr::write_csv(wb_income_history,
                 here::here("inst", "extdata", "wb_income_history.csv"))
