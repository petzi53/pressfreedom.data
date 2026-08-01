# Normalize Column Names to Target Structure

Applies period-specific column mappings to raw data. Renames columns and
adds NA columns for missing data.

## Usage

``` r
normalize_column_names(df, period, year, mapping)
```

## Arguments

- df:

  Data frame to normalize

- period:

  Character. One of "1", "2", or "3"

- year:

  Numeric. Year of the data (used for Period 3 score detection)

- mapping:

  List. Column mapping dictionary

## Value

Data frame with normalized column names in target order

## Details

This function: 1. Detects the score column name for Period 3 2. Renames
raw columns to target names 3. Adds NA columns for missing data 4.
Reorders to match target column order
