# pressfreedom.data

[![pressfreedom.data
logo](reference/figures/logo.png)](https://petzi53.github.io/pressfreedom.data/man/figures/logo.png)

An R package for downloading, cleaning, and standardizing press freedom
data from Reporters Without Borders (Reporters Sans Frontières, RSF).

## Overview

The Reporters Without Borders Press Freedom Index ranks countries by
press freedom on an annual basis. This package automates the download,
cleaning, and standardization of that index, providing a single clean
dataset — `rwb_standardized` (4,192 rows, 191 countries, 20 columns) —
ready for analysis. See
[`vignette("getting-started", package = "pressfreedom.data")`](https://petzi53.github.io/pressfreedom.data/articles/getting-started.md)
for the full pipeline story.

## Installation

**From GitHub (recommended pre-CRAN):**

``` r

pak::pak("petzi53/pressfreedom.data")

# or, using the classic alternative:
remotes::install_github("petzi53/pressfreedom.data")
```

**From source / local clone (development):**

``` r

devtools::install()
```

**From CRAN** (once available):

``` r

# install.packages("pressfreedom.data")
```

## Quick Start

### Load the Dataset

``` r

library(pressfreedom.data)

# Load the standardized dataset
data(rwb_standardized)

# View first few rows
head(rwb_standardized)
```

### Explore the Data

``` r

# Check structure
str(rwb_standardized)

# Summary by year
rwb_standardized |>
  dplyr::group_by(year_n) |>
  dplyr::summarise(
    n_countries = dplyr::n_distinct(country_en),
    avg_score = mean(score, na.rm = TRUE),
    .groups = "drop"
  )

# Track a specific country
rwb_standardized |>
  dplyr::filter(country_en == "Germany") |>
  dplyr::select(year_n, country_en, score, rank)
```

See
[`vignette("getting-started", package = "pressfreedom.data")`](https://petzi53.github.io/pressfreedom.data/articles/getting-started.md)
for a full walkthrough and FAQ.

## Data Structure

### Main Dataset: `rwb_standardized`

Key columns at a glance:

| Column       | Type      | Description                                     |
|--------------|-----------|-------------------------------------------------|
| `year_n`     | integer   | Year (2002–2026; 2011 missing)                  |
| `iso`        | character | ISO 3166-1 alpha-3 country code                 |
| `country_en` | character | Country name (English, ASCII)                   |
| `score`      | numeric   | Press freedom score (0–100; higher = less free) |
| `rank`       | integer   | Rank among countries this year                  |

See
[`?rwb_standardized`](https://petzi53.github.io/pressfreedom.data/reference/rwb_standardized.md)
for the complete data dictionary (all 20 columns).

### Data Notes

Scores are only comparable from 2013 onward (RSF changed its scoring
methodology that year), and dimension columns (political/economic/legal/
social/safety) only exist from 2022 onward. See
[`vignette("getting-started", package = "pressfreedom.data")`](https://petzi53.github.io/pressfreedom.data/articles/getting-started.md)
for the full FAQ, including country consolidation and ISO code coverage.

## Data Source

**Reporters Without Borders (RSF)**  
URL: <https://rsf.org/>  
Press Freedom Index: <https://rsf.org/en/index>

Data available for 24 years (2002–2026, with 2011 missing due to RSF not
publishing that year).

## Development

This package’s public interface is just the `rwb_standardized` dataset
([`?rwb_standardized`](https://petzi53.github.io/pressfreedom.data/reference/rwb_standardized.md)).
Data collection and update tooling (downloading, cleaning, combining,
standardizing new RSF releases) are internal, maintainer-only functions
– they hard-code paths that only resolve inside a development checkout
and the update workflow performs a `git commit`, so they cannot run
against an installed copy of the package. Annual updates are performed
via the runbook script `data-raw/update-data.R`, which requires
`devtools::load_all()`. See `pressfreedom.data:::update_rwb_data` etc.
for advanced/development use.

After cloning, enable the versioned git hooks (blocks accidental
non-ASCII characters in R source/documentation, which break
`R CMD check` portability):

``` bash
git config core.hooksPath .githooks
```

## License

MIT License. See LICENSE file for details.

## Author

Peter Baumgartner  
Email: <petzi53@gmail.com>  
ORCID: 0000-0003-4526-8791

## Citation

If you use this package in research, please cite it:

``` r

citation("pressfreedom.data")
```

## Related Projects

- {pressfreedom} — Interactive Shiny dashboard built on this package (in
  development, not yet published; will be at
  github.com/petzi53/pressfreedom and
  peter-baumgartner.net/pressfreedom)
- RSF Official Data: <https://rsf.org/en/index>
