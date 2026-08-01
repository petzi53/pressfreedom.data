# Combine Cleaned RDS Files from All Periods

Reads all cleaned RDS files from period_1, period_2, and period_3
directories and combines them into a single data frame.

## Usage

``` r
combine_cleaned_periods(
  input_dir = here::here("data", "cleaned"),
  output_file = here::here("data", "processed", "rwb_combined.rds")
)
```

## Arguments

- input_dir:

  Directory containing period subdirectories (period_1, period_2,
  period_3)

- output_file:

  Path where combined RDS file should be saved

## Value

Invisibly returns the path to the output file
