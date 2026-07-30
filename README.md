# pressfreedom.data

An R package for downloading, cleaning, and standardizing press freedom data from Reporters Without Borders (Reporters Sans Frontières, RSF).

## Overview

The Reporters Without Borders Press Freedom Index ranks countries by press freedom on an annual basis. This package automates the complete data pipeline:

1. **Download** — Fetch CSV files from RSF for years 2002–2026
2. **Normalize** — Standardize column names across three distinct RSF methodological periods
3. **Combine** — Merge periods into a unified 20-column structure
4. **Standardize** — Consolidate duplicate country entities and assign ISO 3166 codes

The result is a single, clean dataset ready for analysis: `rwb_standardized` with 4,192 rows, 191 countries, and 20 standardized columns.

## Installation

```r
# Install development version from source
devtools::install()
```

## Quick Start

### Load the Dataset

```r
library(pressfreedom.data)

# Load the standardized dataset
data(rwb_standardized)

# View first few rows
head(rwb_standardized)
```

### Explore the Data

```r
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

## Annual Updates

When new RSF data is published (typically in 2–3 weeks), update the package with a single function call:

```r
library(pressfreedom.data)

# Auto-detects missing years, downloads, cleans, combines, standardizes
result <- update_rwb_data()

# Check the result
print(result)
```

The `update_rwb_data()` function:
- Automatically detects which years are missing
- Downloads CSVs from RSF
- Normalizes column names (Phase B)
- Combines into a unified structure (Phase C)
- Standardizes country names and ISO codes (Phase D)
- Validates the output
- Commits changes to git (if enabled)

For manual control over which phases to run:

```r
# Dry-run (combine and standardize only, no download)
result <- update_rwb_data(
  download = FALSE,
  clean = FALSE,
  standardize = TRUE,
  validate = TRUE
)

# Download specific years only
result <- update_rwb_data(years = 2027:2028)
```

See `?update_rwb_data` for full documentation.

## Data Structure

### Main Dataset: `rwb_standardized`

| Column | Type | Description |
|--------|------|-------------|
| `year_n` | integer | Year (2002–2026; 2011 missing) |
| `iso` | character | ISO 3166-1 alpha-3 country code |
| `country_en` | character | Country name (English, ASCII) |
| `score` | numeric | Press freedom score (0–100; higher = less free) |
| `rank` | integer | Rank among countries this year |
| `political_context` | numeric | Score for political context dimension |
| `rank_pol` | integer | Rank on political dimension |
| `economic_context` | numeric | Score for economic context dimension |
| `rank_eco` | integer | Rank on economic dimension |
| `legal_context` | numeric | Score for legal context dimension |
| `rank_leg` | integer | Rank on legal dimension |
| `social_context` | numeric | Score for social context dimension |
| `rank_soc` | integer | Rank on social dimension |
| `safety` | numeric | Score for safety of journalists dimension |
| `rank_saf` | integer | Rank on safety dimension |
| `zone` | character | Geographical zone (available for earlier years only) |
| `rank_n_1` | integer | Rank in previous year (NA for 2002) |
| `rank_evolution` | integer | Change in rank vs. previous year |
| `score_n_1` | numeric | Score in previous year (NA for 2002) |
| `score_evolution` | numeric | Change in score vs. previous year |

### Data Notes

- **Year 2011:** Not published by RSF; no imputation performed
- **Periods:** Three distinct methodological periods (2002-2012, 2013-2021, 2022-2026) with different available dimensions
- **Country Consolidation:** 14 countries consolidated due to official name changes or RSF methodology updates (e.g., Turkey → Turkiye, Ivory Coast → Cote d'Ivoire)
- **Territorial Variants:** Cyprus and Northern Cyprus kept separate (different entities)
- **ISO Codes:** All 4,192 rows assigned valid ISO 3166-1 alpha-3 codes

## Functions

### Data Processing Functions

- `download_rwb_data()` — Download CSVs from RSF
- `clean_period_1()`, `clean_period_2()`, `clean_period_3()` — Clean period-specific data
- `clean_all_rwb_years()` — Clean all years
- `combine_cleaned_periods()` — Combine cleaned periods
- `standardize_rwb_countries()` — Standardize country names and ISO codes
- `update_rwb_data()` — Annual update orchestration (recommended)

### Utility Functions

- `get_period()` — Identify RSF methodology period for a year
- `detect_csv_encoding()` — Detect the actual character encoding of a downloaded CSV
- `normalize_column_names()` — Normalize column names to standard format
- `standardize_decimal_separators()` — Convert decimal separators (comma to period)
- `convert_factors_to_character()` — Convert factor columns to character

See function documentation for details:

```r
?update_rwb_data
?download_rwb_data
?rwb_standardized
```

## Data Source

**Reporters Without Borders (RSF)**  
URL: https://rsf.org/  
Press Freedom Index: https://rsf.org/en/ranking

Data available for 24 years (2002–2026, with 2011 missing due to RSF not publishing that year).

## Development

After cloning, enable the versioned git hooks (blocks accidental non-ASCII
characters in R source/documentation, which break `R CMD check` portability):

```bash
git config core.hooksPath .githooks
```

## License

MIT License. See LICENSE file for details.

## Author

Peter Baumgartner  
Email: petzi53@gmail.com  
ORCID: 0000-0003-4526-8791

## Citation

If you use this package in research, please cite:

```
@software{baumgartner2026pressfreedom,
  author = {Baumgartner, Peter},
  title = {pressfreedom.data: Download and Process Reporters Without Borders Press Freedom Index Data},
  year = {2026},
  url = {https://github.com/petzi53/pressfreedom.data},
  note = {R package version 0.1.0}
}
```

## Related Projects

- **pressfreedom** — Interactive Shiny dashboard built on this package
- RSF Official Rankings: https://rsf.org/en/ranking
