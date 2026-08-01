# Clean Period 2 Data (2013-2021)

Normalizes Period 2 raw data to the unified 20-column structure.
Identical structure to Period 1 (same columns, encoding). Scores are
comparable across 2013-2021 due to methodology introduced in 2013.

## Usage

``` r
clean_period_2(filepath, year)
```

## Arguments

- filepath:

  Character. Path to raw CSV file

- year:

  Numeric. Year of the data

## Value

Data frame with 20 columns, standardized types (character, numeric)
