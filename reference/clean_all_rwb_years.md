# Batch Clean All RSF Years

Processes all available raw CSV files and produces cleaned RDS files.
Automatically detects period for each year and applies appropriate
transformations.

## Usage

``` r
clean_all_rwb_years(input_dir, output_dir)
```

## Arguments

- input_dir:

  Character. Directory containing raw CSV files. Required (no default)
  so the function never reads from a package or home directory
  implicitly.

- output_dir:

  Character. Directory to save cleaned RDS files. Required (no default)
  so the function never writes to a package or home directory
  implicitly.

## Value

Data frame with processing summary: - year: Year processed - period:
Period (1, 2, or 3) - status: "success" or "error" - message: Details or
error message - output_file: Path to cleaned RDS (if successful)

## Details

This function: 1. Lists all rwbYYYY.csv files in input_dir 2. Extracts
years and detects periods 3. Calls clean_rwb_single() for each year 4.
Catches and logs errors for failed years 5. Creates period-specific
subdirectories (period_1/, period_2/, period_3/) 6. Returns summary of
processing results

Processing proceeds in year order (2002-2026, excluding 2011). Skips
years without data files.
