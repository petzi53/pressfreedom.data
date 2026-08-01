# Validate Standardization Output

Check that standardization preserved data integrity and produced
expected results.

## Usage

``` r
validate_standardization(standardized, original_row_count)
```

## Arguments

- standardized:

  Data frame with standardized country data

- original_row_count:

  Original number of rows (before consolidation)

## Value

Invisibly returns TRUE if all checks pass
