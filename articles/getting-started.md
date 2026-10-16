# Getting Started

## Why This Package?

The Reporters Without Borders (RSF) Press Freedom Index measures press
freedom across countries annually. {pressfreedom.data} automates
downloading, cleaning, and standardizing this data for analysis in R.

The RSF index spans 24 years (2002-2026, with 2011 missing because RSF
did not publish that year) across three methodologically distinct
periods:

- **2002-2012:** 16 columns, non-comparable scores
- **2013-2021:** 16 columns, comparable 0-100 scale
- **2022-2026:** 22-25 columns with new dimensions (Political, Economic,
  Legal, Social, Safety)

On top of the structural changes, countries have been renamed or
reclassified over time – 14 pairs have been consolidated to a single,
current name, including:

- Turkey -\> Turkiye (official name change, 2022)
- Ivory Coast -\> Cote d’Ivoire (RSF standardization)
- Czech Republic -\> Czechia (official name change)

Territorial variants are also resolved: Cyprus and Northern Cyprus are
kept as separate rows (they are distinct political entities), while
other territorial fragments (e.g., U.S. bases in Iraq) are removed. The
audit trail for these decisions – which rows were consolidated and from
what original name – is preserved in
`data/processed/rwb_standardized.rds` inside the package source, though
it is not part of the exported `rwb_standardized` dataset described
below.

Every row in the exported dataset has a valid ISO 3166-1 alpha-3 country
code, so you can join it with other datasets without extra cleanup. We
also found and fixed a subtle scaling bug in RSF’s raw score exports
that had silently inflated many 2013-2026 scores by 100x (see the FAQ
below for details).

This package handles all of the above automatically, providing a single,
clean dataset ready for analysis.

If you haven’t installed the package yet, see the [README’s Installation
section](https://github.com/petzi53/pressfreedom.data#installation).

## Quick Start

### Load and Explore the Data

``` r

library(pressfreedom.data)

data(rwb_standardized)
dplyr::glimpse(rwb_standardized)
#> Rows: 4,183
#> Columns: 51
#> $ year_n                 <dbl> 2002, 2002, 2002, 2002, 2002, 2002, 2002, 2002,…
#> $ iso                    <chr> "AFG", "DZA", "AGO", "ARG", "AUS", "AUT", "AZE"…
#> $ score                  <dbl> 35.50, 31.00, 30.17, 12.00, 3.50, 7.50, 34.50, …
#> $ rank                   <dbl> 104, 95, 93, 42, 12, 27, 101, 67, 118, 124, 13,…
#> $ political_context      <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ rank_pol               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ economic_context       <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ rank_eco               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ legal_context          <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ rank_leg               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ social_context         <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ rank_soc               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ safety                 <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ rank_saf               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ zone                   <chr> "Asia-Pacific", "Middle East & North Africa", "…
#> $ rank_n_1               <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ rank_evolution         <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ score_n_1              <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ score_evolution        <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ country_en             <chr> "Afghanistan", "Algeria", "Angola", "Argentina"…
#> $ EU                     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE,…
#> $ OECD                   <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, …
#> $ un_region              <chr> "Asia", "Africa", "Africa", "Americas", "Oceani…
#> $ un_subregion           <chr> "Southern Asia", "Northern Africa", "Sub-Sahara…
#> $ un_intermediate_region <chr> "Southern Asia", "Northern Africa", "Middle Afr…
#> $ LLDC                   <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, …
#> $ SIDS                   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ LDC                    <lgl> TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, …
#> $ wb_region              <chr> "Middle East, North Africa, Afghanistan & Pakis…
#> $ wb_region2             <chr> "Middle East, North Africa, Afghanistan & Pakis…
#> $ wb_region2_code        <chr> "MNA", "MNA", "AFE", "LCN", "EAS", "ECS", "ECS"…
#> $ wb_lending_category    <chr> "IDA", "IBRD", "IBRD", "IBRD", NA, NA, "IBRD", …
#> $ arab_world             <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ central_europe_baltics <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ small_states           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ IDA_IBRD_total         <lgl> TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, FAL…
#> $ IDA_total              <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ IDA_only               <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ IDA_blend              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ IBRD_only              <lgl> FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, FA…
#> $ wb_income_group        <chr> "Low income", "Lower middle income", "Low incom…
#> $ middle_income          <lgl> FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, …
#> $ low_middle_income      <lgl> TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRU…
#> $ UN                     <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,…
#> $ euro_area              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE,…
#> $ fragile_state          <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ HIPC                   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ population_mn          <dbl> 21.378117, 31.750835, 17.327699, 38.029349, 19.…
#> $ gdp_usd_mn             <dbl> 3825.7014, 61516.1034, 15285.5924, 97724.0043, …
#> $ area_km2               <dbl> 653000, 2382000, 1247000, 2796000, 7692000, 840…
#> $ gdp_pc_usd             <dbl> 178.9541, 1937.4641, 882.1478, 2569.6996, 20301…
```

See
[`?rwb_standardized`](https://www.peter-baumgartner.net/pressfreedom.data/reference/rwb_standardized.md)
for the full column reference.

### Check Data Availability

``` r

# Years available
unique(sort(rwb_standardized$year_n))
#>  [1] 2002 2003 2004 2005 2006 2007 2008 2009 2010 2012 2013 2014 2015 2016 2017
#> [16] 2018 2019 2020 2021 2022 2023 2024 2025 2026

# Number of countries per year
rwb_standardized |>
  dplyr::group_by(year_n) |>
  dplyr::summarise(
    n_countries = dplyr::n_distinct(country_en),
    .groups = "drop"
  )
#> # A tibble: 24 × 2
#>    year_n n_countries
#>     <dbl>       <int>
#>  1   2002         139
#>  2   2003         164
#>  3   2004         165
#>  4   2005         166
#>  5   2006         166
#>  6   2007         167
#>  7   2008         171
#>  8   2009         173
#>  9   2010         176
#> 10   2012         177
#> # ℹ 14 more rows
```

## FAQ & Troubleshooting

### Q: Why is 2011 missing?

**A:** RSF did not publish a Press Freedom Index for 2011. The package
preserves this gap rather than imputing values.

### Q: Are scores comparable across all 24 years?

**A:** No. RSF changed its scoring methodology in 2013, so scores from
2002-2012 are not directly comparable to 2013-2026. When analyzing
trends over time, restrict comparisons to the 2013-2026 period unless
you are specifically studying methodology effects.

### Q: Are dimensions available for all years?

**A:** No. The new dimensions (Political, Economic, Legal, Social,
Safety) are only available from 2022 onward. Earlier years have `NA`
values.

### Q: Was there a scaling issue in the raw scores?

**A:** Yes. RSF’s source files store percentages as bare digits with
implied decimals (e.g., “9189” means 91.89%) and drop trailing zeros
inconsistently, which had left many 2013-2026 scores up to 100x too
large in earlier cleaning attempts. This is now corrected automatically
via
[`resolve_percent_scaling()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/resolve_percent_scaling.md)
before export, so the `score` values you see are already on the correct
0-100 scale.

### Q: Can I use ISO codes to join with other datasets?

**A:** Yes. All rows have valid ISO 3166-1 alpha-3 codes in the `iso`
column. This is the standard for country joins.

### Q: Can I use the data on different platforms?

**A:** Yes. The data is normalized to ASCII, with special characters
removed (e.g., Cote d’Ivoire, Turkiye), so it loads and joins correctly
regardless of your operating system or locale settings.

### Q: Can I use this data in published research?

**A:** Yes. RSF publishes the Press Freedom Index publicly to support
journalism, research, and policy analysis, and does not restrict reuse
for these purposes. See the next entry for citation templates.

### Q: How should I cite this data?

**A:** Please cite the package:

``` r

citation("pressfreedom.data")
```

This also includes a pointer to citing RSF’s original Press Freedom
Index data, since the package citation does not cover the underlying
dataset.

### Q: How do I contribute corrections or suggestions?

**A:** Open an issue on GitHub:
<https://github.com/petzi53/pressfreedom.data/issues>

### Q: Where can I learn more about the data?

**A:** There are different places to learn more about the data:

- For background information on the RSF Press Freedom Index itself,
  visit <https://rsf.org/en/index>.
- For chart-based examples using this package, see the companion
  vignette
  [`vignette("visualizing-trends", package = "pressfreedom.data")`](https://www.peter-baumgartner.net/pressfreedom.data/articles/visualizing-trends.md).
- For a full description of the dataset’s columns and how it was built,
  see
  [`?rwb_standardized`](https://www.peter-baumgartner.net/pressfreedom.data/reference/rwb_standardized.md)
  in R.
