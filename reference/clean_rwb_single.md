# Clean Single Year of RSF Data

Dispatcher function that routes to appropriate period-specific cleaner.
Reads raw CSV, applies period-specific transformations, saves as RDS.

## Usage

``` r
clean_rwb_single(filepath, year, output_dir)
```

## Arguments

- filepath:

  Character. Path to raw CSV file

- year:

  Numeric. Year of the data

- output_dir:

  Character. Directory to save cleaned RDS file

## Value

Invisible. Writes RDS file to output_dir. Filename format:
rwbYYYY_cleaned.rds

## Details

This function: 1. Detects period from year using get_period() 2. Routes
to clean_period_1(), clean_period_2(), or clean_period_3() 3. Validates
output has 20 columns in correct order 4. Saves as RDS file in
output_dir 5. Returns invisible filepath (for logging/progress tracking)
