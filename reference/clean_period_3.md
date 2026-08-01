# Clean Period 3 Data (2022-2026)

Normalizes Period 3 raw data to the unified 20-column structure. Handles
UTF-8 encoding, year-specific score column naming, dimension columns,
and decimal separator conversion for score_evolution.

## Usage

``` r
clean_period_3(filepath, year)
```

## Arguments

- filepath:

  Character. Path to raw CSV file

- year:

  Numeric. Year of the data

## Value

Data frame with 20 columns, standardized types (character, numeric)

## Details

Processing steps: 1. Detect file encoding (RSF has silently switched
between UTF-8 and ISO-8859-1 across Period 3 years, e.g. 2025-2026
exports arrived as Latin-1 even though 2022-2024 were UTF-8) and read
accordingly 2. Detect score column name (Score, Score YYYY, etc.) 3.
Drop problematic columns (Situation, etc.) 4. Rename columns per Period
3 mapping 5. Convert iso, country_en, zone to character 6. Convert
numeric columns to numeric type 7. Apply decimal separator conversion to
all numeric columns (handles score_evolution) 8. Set score_n_1 and
score_evolution to NA for 2022 9. Reorder to target 20-column structure
