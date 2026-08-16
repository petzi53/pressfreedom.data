# Normalize Column Names to Target Structure

Applies period-specific column mappings to raw data. Renames columns and
adds NA columns for missing data.

## Usage

``` r
normalize_column_names(df, mapping)
```

## Arguments

- df:

  Data frame to normalize

- mapping:

  List. Column mapping dictionary, already resolved (e.g. any
  period/year-specific overrides from \`apply_column_overrides()\`
  applied) before this function is called

## Value

Data frame with normalized column names in target order

## Details

This function: 1. Renames raw columns to target names 2. Adds NA columns
for missing data 3. Reorders to match target column order
