#' Add M49 UN Regional Classifications
#'
#' Joins `inst/extdata/m49_lookup.csv` on iso.
#' Adds columns: `un_region`, `un_subregion`, `un_intermediate_region`, `LLDC`, `SIDS`.
#'
#' @param df A data frame with an `iso` column (3-letter country code).
#' @return The input data frame with five UN/M49 classification columns added.
#' @noRd
add_m49_columns <- function(df) {
  m49_path <- system.file("extdata", "m49_lookup.csv",
                          package = "pressfreedom.data")
  m49_lookup <- readr::read_csv(
    m49_path,
    col_types = readr::cols(
      iso                    = readr::col_character(),
      un_region              = readr::col_character(),
      un_subregion           = readr::col_character(),
      un_intermediate_region = readr::col_character(),
      LLDC                   = readr::col_logical(),
      SIDS                   = readr::col_logical()
    )
  )
  df |> dplyr::left_join(m49_lookup, by = "iso")
}

#' Add Time-Varying LDC (Least Developed Country) Status
#'
#' Joins `inst/extdata/ldc_history.csv` on iso and year_n.
#' Adds column: `LDC`.
#'
#' LDC status is determined by UN CDP reviews (triennial, 2000-2024).
#' Intermediate years use nearest-prior review interpolation.
#' Developed countries (not in any review) are coded as FALSE.
#' Northern Cyprus (`CXX`) is coded as NA.
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with the `LDC` column added.
#' @noRd
add_ldc_timevary_column <- function(df) {
  ldc_path <- system.file("extdata", "ldc_history.csv",
                          package = "pressfreedom.data")
  ldc_history <- readr::read_csv(
    ldc_path,
    col_types = readr::cols(
      iso    = readr::col_character(),
      year_n = readr::col_integer(),
      LDC    = readr::col_logical()
    )
  )
  df |>
    dplyr::left_join(ldc_history, by = c("iso", "year_n")) |>
    dplyr::mutate(
      # The lookup only covers countries in the CDP review files, so
      # developed countries (e.g. DEU) join as NA: they are not LDCs.
      # CXX (Northern Cyprus) stays NA, consistent with all other new columns.
      LDC = dplyr::if_else(
        .data$iso == "CXX",
        NA,
        dplyr::coalesce(.data$LDC, FALSE)
      )
    )
}

#' Add World Bank Static Classifications
#'
#' Joins `inst/extdata/wb_static_lookup.csv` on iso.
#' Adds columns: `wb_region`, `wb_region2`, `wb_region2_code`, `wb_lending_category`,
#' `arab_world`, `central_europe_baltics`, `small_states`, `IDA_IBRD_total`, `IDA_total`,
#' `IDA_only`, `IDA_blend`, `IBRD_only`.
#'
#' All classifications are static snapshots from World Bank CLASS (July 2026).
#' `wb_region2` splits Sub-Saharan Africa into AFE (Eastern and Southern) and AFW (Western and Central).
#'
#' @param df A data frame with an `iso` column.
#' @return The input data frame with 13 World Bank static classification columns added.
#' @noRd
add_wb_static_columns <- function(df) {
  wb_path <- system.file("extdata", "wb_static_lookup.csv",
                         package = "pressfreedom.data")
  wb_static <- readr::read_csv(
    wb_path,
    col_types = readr::cols(
      iso                    = readr::col_character(),
      wb_region              = readr::col_character(),
      wb_region2             = readr::col_character(),
      wb_region2_code        = readr::col_character(),
      wb_lending_category    = readr::col_character(),
      arab_world             = readr::col_logical(),
      central_europe_baltics = readr::col_logical(),
      small_states           = readr::col_logical(),
      IDA_IBRD_total         = readr::col_logical(),
      IDA_total              = readr::col_logical(),
      IDA_only               = readr::col_logical(),
      IDA_blend              = readr::col_logical(),
      IBRD_only              = readr::col_logical()
    )
  )
  df |> dplyr::left_join(wb_static, by = "iso")
}

#' Add Time-Varying World Bank Income Classifications
#'
#' Joins `inst/extdata/wb_income_history.csv` on iso and year_n.
#' Adds columns: `wb_income_group`, `middle_income`, `low_middle_income`.
#'
#' `wb_income_group` is from World Bank operational guidelines history (OGHIST).
#' Values: "Low income", "Lower middle income", "Upper middle income", "High income".
#' `middle_income` = TRUE if Lower or Upper middle income.
#' `low_middle_income` = TRUE if not High income (includes Low, Lower middle, Upper middle).
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with three World Bank income-related columns added.
#' @noRd
add_wb_timevary_columns <- function(df) {
  income_path <- system.file("extdata", "wb_income_history.csv",
                             package = "pressfreedom.data")
  wb_income_history <- readr::read_csv(
    income_path,
    col_types = readr::cols(
      iso             = readr::col_character(),
      year_n          = readr::col_integer(),
      wb_income_group = readr::col_character()
    )
  )
  df |>
    dplyr::left_join(wb_income_history, by = c("iso", "year_n")) |>
    dplyr::mutate(
      middle_income = .data$wb_income_group %in%
                        c("Lower middle income", "Upper middle income"),
      low_middle_income = !is.na(.data$wb_income_group) &
                            .data$wb_income_group != "High income"
    )
}

#' Add Time-Varying UN Membership Status
#'
#' Adds column: `UN`.
#'
#' Default: all countries are UN members (TRUE), except:
#' - PSE (Palestine), TWN (Taiwan), XXK (Kosovo): always FALSE
#' - MNE (Montenegro): FALSE before 2006 (joined June 28, 2006)
#' - SSD (South Sudan): FALSE before 2012 (joined July 14, 2011; first RSF year is 2012)
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with the `UN` column added.
#' @noRd
add_un_timevary_column <- function(df) {
  df |>
    dplyr::mutate(
      UN = dplyr::case_when(
        # Non-members throughout (XXK = Kosovo's iso in rwb_standardized, not XKX)
        .data$iso %in% c("PSE", "TWN", "XXK") ~ FALSE,
        # Late joiners: FALSE before joining year
        .data$iso == "MNE" & .data$year_n < 2006L ~ FALSE,  # joined June 28, 2006
        .data$iso == "SSD" & .data$year_n < 2012L ~ FALSE,  # joined July 14, 2011;
                                                             # first RSF year is 2012
        # All others TRUE
        TRUE ~ TRUE
      )
    )
}

#' Add Time-Varying Euro Area Membership
#'
#' Adds column: `euro_area`.
#'
#' TRUE for countries in the eurozone in a given year.
#' Founding members (12) have coins/notes from Jan 1, 2002.
#' Later accessions: Slovenia (2007), Cyprus/Malta (2008), Slovakia (2009),
#' Estonia (2012), Latvia (2014), Lithuania (2015), Croatia (2023).
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with the `euro_area` column added.
#' @noRd
add_euro_area_timevary_column <- function(df) {
  euro_members <- tibble::tribble(
    ~iso,  ~from,
    # 12 founding members (coins/notes introduced Jan 1, 2002)
    "BEL", 2002L,
    "DEU", 2002L,
    "IRL", 2002L,
    "GRC", 2002L,   # joined Jan 2001
    "ESP", 2002L,
    "FRA", 2002L,
    "ITA", 2002L,
    "LUX", 2002L,
    "NLD", 2002L,
    "AUT", 2002L,
    "PRT", 2002L,
    "FIN", 2002L,
    # Later accessions
    "SVN", 2007L,
    "CYP", 2008L,
    "MLT", 2008L,
    "SVK", 2009L,
    "EST", 2012L,   # joined Jan 2011; 2011 absent from RSF; first appearance 2012
    "LVA", 2014L,
    "LTU", 2015L,
    "HRV", 2023L
  )

  df |>
    dplyr::left_join(
      euro_members |> dplyr::rename(euro_from = "from"),
      by = "iso"
    ) |>
    dplyr::mutate(
      euro_area = dplyr::case_when(
        is.na(.data$euro_from)              ~ FALSE,
        .data$year_n >= .data$euro_from     ~ TRUE,
        TRUE                                ~ FALSE
      )
    ) |>
    dplyr::select(-"euro_from")
}

#' Add Time-Varying Fragile and Conflict-Affected States Status
#'
#' Joins `inst/extdata/fcs_history.csv` on iso and year_n.
#' Adds column: `fragile_state`.
#'
#' Classification from World Bank's List of Fragile and Conflict-Affected Situations (FY2006-FY2026).
#' RSF years 2002-2005: NA (WB FCS list did not exist before FY2006).
#' FY2006+: FALSE for countries never on any FCS list.
#'
#' Note: The supplement CSV includes all severity tiers (Severe/Core/Marginal) collapsed to TRUE.
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with the `fragile_state` column added.
#' @noRd
add_fcs_timevary_column <- function(df) {
  fcs_path <- system.file("extdata", "fcs_history.csv",
                          package = "pressfreedom.data")
  fcs_history <- readr::read_csv(
    fcs_path,
    col_types = readr::cols(
      iso           = readr::col_character(),
      year_n        = readr::col_integer(),
      fragile_state = readr::col_logical()
    )
  )

  df |>
    dplyr::left_join(fcs_history, by = c("iso", "year_n")) |>
    dplyr::mutate(
      # FY2006+: not in fcs_history means not fragile -> FALSE
      # 2002-2005: no FCS list existed -> keep NA
      fragile_state = dplyr::if_else(
        .data$year_n >= 2006L & is.na(.data$fragile_state),
        FALSE,
        .data$fragile_state
      )
    )
}

#' Add Time-Varying HIPC Initiative Completion Status
#'
#' Adds column: `HIPC`.
#'
#' TRUE for Heavily Indebted Poor Countries that have completed the HIPC Initiative
#' in a given year. 34 countries total; those completing before 2002 are coded as TRUE
#' from the start of RSF coverage (2002).
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with the `HIPC` column added.
#' @noRd
add_hipc_timevary_column <- function(df) {
  hipc_completion <- tibble::tribble(
    ~iso,  ~from,
    # Completed before RSF coverage (from = 2002)
    "UGA", 2002L,   # May 2000
    "TZA", 2002L,   # November 2001
    "MOZ", 2002L,   # September 2001
    "BOL", 2002L,   # June 2001
    # Completed during RSF coverage
    "BFA", 2002L,   # April 2002
    "MRT", 2002L,   # June 2002
    "BEN", 2003L,   # March 2003
    "MLI", 2003L,   # March 2003
    "GUY", 2003L,   # December 2003
    "NIC", 2004L,   # January 2004
    "GHA", 2004L,   # July 2004
    "SEN", 2004L,   # April 2004
    "ETH", 2004L,   # April 2004
    "NER", 2004L,   # April 2004
    "MDG", 2004L,   # October 2004
    "RWA", 2005L,   # April 2005
    "HND", 2005L,   # April 2005
    "ZMB", 2005L,   # April 2005
    "MWI", 2006L,   # August 2006
    "SLE", 2006L,   # December 2006
    "STP", 2007L,   # March 2007
    "BDI", 2009L,   # January 2009
    "HTI", 2009L,   # June 2009
    "CAF", 2009L,   # June 2009
    "AFG", 2010L,   # January 2010
    "COG", 2010L,   # January 2010
    "LBR", 2010L,   # June 2010
    "COD", 2010L,   # July 2010
    "GNB", 2010L,   # December 2010
    "TGO", 2010L,   # December 2010
    "CIV", 2012L,   # June 2012
    "GIN", 2012L,   # September 2012
    "COM", 2012L,   # December 2012
    "TCD", 2015L    # April 2015
  )

  df |>
    dplyr::left_join(
      hipc_completion |> dplyr::rename(hipc_from = "from"),
      by = "iso"
    ) |>
    dplyr::mutate(
      HIPC = dplyr::case_when(
        is.na(.data$hipc_from)          ~ FALSE,
        .data$year_n >= .data$hipc_from ~ TRUE,
        TRUE                            ~ FALSE
      )
    ) |>
    dplyr::select(-"hipc_from")
}

#' Add World Bank Socioeconomic Data (Population, GDP, Area)
#'
#' Joins three lookup files: `inst/extdata/wb_population.csv`,
#' `inst/extdata/wb_gdp.csv`, and `inst/extdata/unsd_syb_area.csv`.
#' Adds columns: `population_mn`, `area_km2`, `gdp_usd_mn`, `gdp_pc_usd`.
#'
#' Population and GDP join on iso and year_n (annual data, 2002-2024/2023).
#' Years 2025-2026 population and 2024-2026 GDP are forward-filled from the last
#' available year. Area is static (one value per country).
#'
#' `gdp_pc_usd` is derived: USD millions / population millions.
#' Returns NA if either population or GDP is missing.
#'
#' @param df A data frame with `iso` and `year_n` columns.
#' @return The input data frame with four socioeconomic columns added.
#' @noRd
add_wb_socioeconomic_columns <- function(df) {
  pop_lookup <- readr::read_csv(
    system.file("extdata", "wb_population.csv", package = "pressfreedom.data"),
    col_types = readr::cols(
      iso           = readr::col_character(),
      year          = readr::col_integer(),
      population_mn = readr::col_double()
    )
  )
  gdp_lookup <- readr::read_csv(
    system.file("extdata", "wb_gdp.csv", package = "pressfreedom.data"),
    col_types = readr::cols(
      iso        = readr::col_character(),
      year       = readr::col_integer(),
      gdp_usd_mn = readr::col_double()
    )
  )
  area_lookup <- readr::read_csv(
    system.file("extdata", "unsd_syb_area.csv", package = "pressfreedom.data"),
    col_types = readr::cols(
      iso      = readr::col_character(),
      area_km2 = readr::col_double()
    )
  )

  df |>
    dplyr::left_join(pop_lookup,  by = c("iso", "year_n" = "year")) |>
    dplyr::left_join(gdp_lookup,  by = c("iso", "year_n" = "year")) |>
    dplyr::left_join(area_lookup, by = "iso") |>
    dplyr::mutate(
      gdp_pc_usd = dplyr::if_else(
        !is.na(.data$gdp_usd_mn) & !is.na(.data$population_mn) &
          .data$population_mn > 0,
        .data$gdp_usd_mn / .data$population_mn,
        NA_real_
      )
    )
}
