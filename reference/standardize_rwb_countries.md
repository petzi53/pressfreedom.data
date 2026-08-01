# Standardize RSF Country Data

Main wrapper function for Phase D standardization pipeline. Loads
combined data, applies consolidations, assigns ISO codes, and saves
standardized output.

## Usage

``` r
standardize_rwb_countries(
  input_file = here::here("data", "processed", "rwb_combined.rds"),
  output_file = here::here("data", "processed", "rwb_standardized.rds"),
  mapping_file = NULL
)
```

## Arguments

- input_file:

  Path to combined RDS file

- output_file:

  Path to write standardized RDS file

- mapping_file:

  Path to consolidation mapping CSV

## Value

Invisibly returns the path to the output file
