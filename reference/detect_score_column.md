# Detect Score Column Name for Period 3

Period 3 (2022-2026) uses varying score column names. Some years use
"Score", others use "Score YYYY". This function detects which pattern is
present.

## Usage

``` r
detect_score_column(df, year)
```

## Arguments

- df:

  Data frame to inspect

- year:

  Numeric. Year of the data

## Value

Character. Name of the score column (e.g., "Score" or "Score 2026")

## Details

Detection logic: - Check for "Score YYYY" pattern first (e.g., "Score
2026") - Fall back to "Score" if year-specific name not found - Return
NA if neither found
