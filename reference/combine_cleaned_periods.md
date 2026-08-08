# Combine Cleaned RDS Files from All Periods

Reads all cleaned RDS files from period_1, period_2, and period_3
directories and combines them into a single data frame.

## Usage

``` r
combine_cleaned_periods(input_dir, output_file)
```

## Arguments

- input_dir:

  Directory containing period subdirectories (period_1, period_2,
  period_3). Required (no default) so the function never reads from a
  package or home directory implicitly.

- output_file:

  Path where combined RDS file should be saved. Required (no default) so
  the function never writes to a package or home directory implicitly.

## Value

Invisibly returns the path to the output file
