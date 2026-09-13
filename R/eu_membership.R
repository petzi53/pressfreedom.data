# EU membership lookup --------------------------------------------------------
#
# Internal helper used by data-raw/rwb_standardized.R to add the `EU` column
# to the exported dataset.

#' Add EU Membership Column
#'
#' Adds a logical column `EU` to a data frame with `iso` and `year_n` columns,
#' indicating whether the country was an EU member in that year.
#'
#' Accession and withdrawal events covered:
#'
#' | Event                    | Year | ISO codes                                           |
#' |--------------------------|------|-----------------------------------------------------|
#' | EU-15 (dataset baseline) | 2002 | AUT BEL DNK FIN FRA DEU GRC IRL ITA LUX NLD PRT ESP SWE GBR |
#' | 2004 enlargement         | 2004 | CYP CZE EST HUN LVA LTU MLT POL SVK SVN            |
#' | 2007 enlargement         | 2007 | BGR ROU                                             |
#' | 2013 enlargement         | 2013 | HRV (joined July 1; after RSF spring publication)   |
#' | Brexit                   | 2020 | GBR left January 31, 2020                          |
#'
#' @param data A data frame with columns `iso` (ISO 3166-1 alpha-3) and
#'   `year_n` (numeric).
#'
#' @return `data` with an additional logical column `EU`.
#'
#' @note Northern Cyprus (CXX) is not an internationally recognised EU member
#'   state and is coded `FALSE` for all years, even though the Republic of
#'   Cyprus (CYP) has been a member since 2004.
#'
#' @note Croatia (HRV) is marked as EU member from 2013, even though its
#'   accession (July 1, 2013) post-dates the RSF spring publication. Change
#'   `from = 2014L` for HRV if publication-date accuracy is preferred.
#'
#' @noRd
add_eu_column <- function(data) {
  # `from`  = first year_n in which membership applies
  # `until` = first year_n in which membership NO LONGER applies (NA = still member)
  eu_events <- tibble::tribble(
    ~iso,  ~from, ~until,
    # EU-15 - members as of 2002 (start of dataset)
    "AUT", 2002L,    NA,
    "BEL", 2002L,    NA,
    "DNK", 2002L,    NA,
    "FIN", 2002L,    NA,
    "FRA", 2002L,    NA,
    "DEU", 2002L,    NA,
    "GRC", 2002L,    NA,
    "IRL", 2002L,    NA,
    "ITA", 2002L,    NA,
    "LUX", 2002L,    NA,
    "NLD", 2002L,    NA,
    "PRT", 2002L,    NA,
    "ESP", 2002L,    NA,
    "SWE", 2002L,    NA,
    "GBR", 2002L, 2020L,  # Brexit: left January 31, 2020
    # 2004 enlargement - May 1, 2004
    "CYP", 2004L,    NA,
    "CZE", 2004L,    NA,
    "EST", 2004L,    NA,
    "HUN", 2004L,    NA,
    "LVA", 2004L,    NA,
    "LTU", 2004L,    NA,
    "MLT", 2004L,    NA,
    "POL", 2004L,    NA,
    "SVK", 2004L,    NA,
    "SVN", 2004L,    NA,
    # 2007 enlargement - January 1, 2007
    "BGR", 2007L,    NA,
    "ROU", 2007L,    NA,
    # 2013 enlargement - July 1, 2013 (after RSF spring publication; see @note)
    "HRV", 2013L,    NA
  )

  data |>
    dplyr::left_join(eu_events, by = "iso") |>
    dplyr::mutate(
      EU = !is.na(from) & year_n >= from & (is.na(until) | year_n < until)
    ) |>
    dplyr::select(-from, -until)
}
