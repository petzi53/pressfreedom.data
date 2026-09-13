#' Add OECD Membership Column to Press Freedom Data
#'
#' Adds a logical column `OECD` to a data frame containing press freedom data,
#' indicating whether a country was an OECD member in a given year.
#'
#' The function uses the `iso` (ISO 3166-1 alpha-3) and `year_n` columns to
#' determine OECD membership status based on historical accession events during
#' 2002-2026:
#'
#' | Membership Period                | Year      | Countries                                  |
#' |----------------------------------|-----------|-------------------------------------------|
#' | OECD-20 founding members         | 1961-2001 | AUT BEL CAN DNK FRA DEU GRC ISL IRL ITA LUX NLD NOR PRT ESP SWE CHE TUR GBR USA |
#' | Expansion to OECD-30 baseline    | 2002      | AUS FIN HUN JPN KOR MEX NZL POL SVK CZE |
#' | 2010 enlargement (OECD-34)       | 2010      | CHL EST ISR SVN                           |
#' | 2016 enlargement (OECD-35)       | 2016      | LVA                                       |
#' | 2018 enlargement (OECD-36)       | 2018      | LTU                                       |
#' | 2020 enlargement (OECD-37)       | 2020      | COL                                       |
#' | 2021 enlargement (OECD-38)       | 2021      | CRI                                       |
#'
#' @param data A data frame containing at least the columns `iso` (character,
#'   ISO 3166-1 alpha-3 country code) and `year_n` (numeric, publication year).
#'   Designed for use with `pressfreedom.data::rwb_standardized`.
#'
#' @return The input data frame with an additional logical column `OECD`:
#'   `TRUE` if the country was an OECD member in that year, `FALSE` otherwise.
#'
#' @examples
#' library(pressfreedom.data)
#' rwb_standardized |> add_oecd_column()
#'
add_oecd_column <- function(data) {
  # Membership events: `from` = first year as OECD member,
  #                    `until` = first year NO LONGER an OECD member (NA = still member)
  oecd_events <- tibble::tribble(
    ~iso,  ~from, ~until,
    # OECD-20 founding members (1961; all present in dataset from 2002 onward)
    "AUT", 1961L,    NA,
    "BEL", 1961L,    NA,
    "CAN", 1961L,    NA,
    "DNK", 1961L,    NA,
    "FRA", 1961L,    NA,
    "DEU", 1961L,    NA,
    "GRC", 1961L,    NA,
    "ISL", 1961L,    NA,
    "IRL", 1961L,    NA,
    "ITA", 1961L,    NA,
    "LUX", 1961L,    NA,
    "NLD", 1961L,    NA,
    "NOR", 1961L,    NA,
    "PRT", 1961L,    NA,
    "ESP", 1961L,    NA,
    "SWE", 1961L,    NA,
    "CHE", 1961L,    NA,
    "TUR", 1961L,    NA,
    "GBR", 1961L,    NA,
    "USA", 1961L,    NA,
    # 1960s and 1970s additions
    "JPN", 1964L,    NA,  # April 28, 1964
    "FIN", 1969L,    NA,  # January 28, 1969
    "AUS", 1971L,    NA,  # June 7, 1971
    "NZL", 1973L,    NA,  # May 29, 1973
    # 1990s additions (before 2002 dataset begins; included for completeness)
    "MEX", 1994L,    NA,  # May 18, 1994
    "CZE", 1995L,    NA,  # December 21, 1995
    "HUN", 1996L,    NA,  # May 7, 1996
    "POL", 1996L,    NA,  # November 22, 1996
    "KOR", 1996L,    NA,  # December 12, 1996
    "SVK", 2000L,    NA,  # December 14, 2000
    # 2010 enlargement
    "CHL", 2010L,    NA,  # May 7, 2010
    "SVN", 2010L,    NA,  # July 21, 2010
    "ISR", 2010L,    NA,  # September 7, 2010
    "EST", 2010L,    NA,  # December 9, 2010
    # 2016 enlargement
    "LVA", 2016L,    NA,  # July 1, 2016
    # 2018 enlargement
    "LTU", 2018L,    NA,  # July 5, 2018
    # 2020 enlargement
    "COL", 2020L,    NA,  # April 28, 2020
    # 2021 enlargement
    "CRI", 2021L,    NA   # May 25, 2021
  )

  data |>
    dplyr::left_join(oecd_events, by = "iso") |>
    dplyr::mutate(
      OECD = !is.na(from) & year_n >= from & (is.na(until) | year_n < until)
    ) |>
    dplyr::select(-from, -until)
}
