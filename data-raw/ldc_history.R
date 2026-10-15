# Build inst/extdata/ldc_history.csv: time-varying LDC status by iso x year_n
#
# Source: UN CDP triennial review datasets (2000-2024), one CSV per review.
# Output columns: iso, year_n, LDC (logical)
#
# Known limitation (documented in R/data.R, no manual overrides): LDC is the
# status as of the most recent triennial review, so actual UN inclusion or
# graduation dates (e.g. SSD, TLS, WSM) can differ from the year shown here.
#
# Notes on the raw files:
# - Each file has a two-row header, then data, then footnote rows.
# - Column NAMES differ between reviews ("ISO - 3", "ISO-3 ", "ISO -3 "), so the
#   first four columns are read by position: Ccode, ISO-3, Country, Status.
# - Status is "LDC" for least developed countries, "ODC" (2024 only) for
#   graduated countries, and empty for other reviewed developing countries.
# - Footnote rows have no 3-letter ISO code and are dropped.

review_years <- c(2000, 2003, 2006, 2009, 2012, 2015, 2018, 2021, 2024)
# 2011 is intentionally missing from the RSF data
rsf_years <- c(2002:2010, 2012:2026)

ldc_dir <- here::here("data-raw", "source", "ldc")

read_ldc_file <- function(year) {
  path <- file.path(ldc_dir, stringr::str_glue("ldc_data-{year}.csv"))
  readr::read_csv(
    path,
    skip = 2,
    col_names = c("ccode", "iso", "country", "status"),
    col_select = 1:4,
    col_types = "cccc",
    show_col_types = FALSE
  ) |>
    dplyr::mutate(iso = stringr::str_trim(.data$iso)) |>
    # Keep real country rows only: exactly three uppercase letters
    dplyr::filter(stringr::str_detect(.data$iso, "^[A-Z]{3}$")) |>
    dplyr::transmute(
      iso = .data$iso,
      review_year = year,
      LDC = !is.na(.data$status) & .data$status == "LDC"
    )
}

ldc_reviews <- purrr::map(review_years, read_ldc_file) |>
  purrr::list_rbind()

stopifnot(
  !anyDuplicated(ldc_reviews[c("iso", "review_year")])
)

# Nearest-prior review for every RSF year (e.g. 2004 -> 2003 review)
year_map <- tibble::tibble(
  year_n = rsf_years,
  review_year = purrr::map_dbl(
    rsf_years,
    \(y) max(review_years[review_years <= y])
  )
)

# Countries absent from a given review (e.g. SSD before 2015, TLS in 2000)
# are not LDCs in that period -> FALSE after the left join
ldc_history <- tidyr::expand_grid(
  iso = unique(ldc_reviews$iso),
  year_n = rsf_years
) |>
  dplyr::left_join(year_map, by = "year_n") |>
  dplyr::left_join(ldc_reviews, by = c("iso", "review_year")) |>
  dplyr::mutate(LDC = dplyr::coalesce(.data$LDC, FALSE)) |>
  dplyr::select("iso", "year_n", "LDC") |>
  dplyr::arrange(.data$iso, .data$year_n)

readr::write_csv(ldc_history, here::here("inst", "extdata", "ldc_history.csv"))
