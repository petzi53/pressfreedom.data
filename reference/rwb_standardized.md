# Standardized Reporters Without Borders Press Freedom Index (2002-2026)

A comprehensive dataset of press freedom indicators from Reporters
Without Borders (RSF: Reporters Sans Frontieres, the organization's
French name and legal identity; RWB: Reporters Without Borders, its
common English name – used for the \`rwb\_\` prefix throughout this
package), standardized and cleaned by the pressfreedom.data package
pipeline.

## Usage

``` r
rwb_standardized
```

## Format

A data frame with 4,192 rows and 20 columns:

- year_n:

  Numeric year (2002-2026, excluding 2011)

- iso:

  ISO 3166-1 alpha-3 country code

- country_en:

  Standardized country name in English

- score:

  Press freedom score (0-100; higher = more free). Comparable only
  within periods.

- rank:

  Rank within the year (1 = most free)

- political_context:

  Sub-index: Political context (if available)

- rank_pol:

  Rank within political context (if available)

- economic_context:

  Sub-index: Economic context (if available)

- rank_eco:

  Rank within economic context (if available)

- legal_context:

  Sub-index: Legal context (if available)

- rank_leg:

  Rank within legal context (if available)

- social_context:

  Sub-index: Social context (if available)

- rank_soc:

  Rank within social context (if available)

- safety:

  Sub-index: Safety (if available)

- rank_saf:

  Rank within safety (if available)

- zone:

  Geographic zone assigned by RSF

- rank_n_1:

  Previous year's rank (year_n - 1)

- rank_evolution:

  Change in rank from previous year

- score_n_1:

  Previous year's score (year_n - 1)

- score_evolution:

  Change in score from previous year

## Source

Reporters Sans Frontieres, https://rsf.org

## Details

\## Data Cleaning Pipeline

This dataset is the output of a comprehensive 4-phase data pipeline
implemented in the pressfreedom.data package:

\- \*\*Phase A (Download):\*\* Raw CSV files from RSF website -
\*\*Phase B (Normalize):\*\* Column names and data types standardized
across periods - \*\*Phase C (Combine):\*\* All periods merged into
unified structure - \*\*Phase D (Standardize):\*\* Country names
consolidated, ISO codes assigned, duplicates resolved

\## Important Notes

\*\*Audit Trail:\*\* The full audit trail (including
\`country_name_original\` and \`consolidation_flag\` columns) is
preserved in the source RDS file
(\`data/processed/rwb_standardized.rds\`) within the pressfreedom.data
package. This exported dataset contains only the 20 core columns for
analysis.

\*\*Score Comparability:\*\* Scores are only comparable within their
respective periods: - \*\*Period 1 (2002-2012):\*\* Non-comparable
scores; use ranks for trends - \*\*Period 2 (2013-2021):\*\* Comparable
scores (0-100 scale) - \*\*Period 3 (2022-2026):\*\* New methodology;
different dimensions tracked

\*\*Missing Data:\*\* Sub-indices (political, economic, legal, social,
safety contexts) are only available in Period 3 (2022-2026). Periods 1-2
have NA values for these columns.

\*\*Cyprus:\*\* Tracked as two separate entities: - "Cyprus" (ISO:
CYP) - Republic of Cyprus - "Northern Cyprus" (ISO: CXX) - Turkish
Republic of Northern Cyprus

## Examples

``` r
if (FALSE) { # \dontrun{
# Load the dataset
data(rwb_standardized)

# Basic summary
head(rwb_standardized)

# Countries included
length(unique(rwb_standardized$country_en))

# Years covered
range(rwb_standardized$year_n)
} # }
```
