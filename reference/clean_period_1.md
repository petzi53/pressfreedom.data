# Clean Period 1 Data (2002-2012)

Normalizes Period 1 raw data to the unified 20-column structure. Handles
ISO-8859-1 encoding, decimal separator conversion, and column mapping.

## Usage

``` r
clean_period_1(filepath, year)
```

## Arguments

- filepath:

  Character. Path to raw CSV file

- year:

  Numeric. Year of the data

## Value

Data frame with 20 columns, standardized types (character, numeric)

## Details

Processing steps: 1. Detect file encoding (RSF's 2002-2021 exports are
actually UTF-8, not ISO-8859-1 as originally assumed) and read
accordingly 2. Convert decimal separators (comma -\> period) 3. Rename
columns per Period 1 mapping 4. Convert iso, country_en, zone to
character 5. Convert numeric columns to numeric type 6. Handle year_n
for 2012 (raw data contains "2011-12" text value) 7. Add NA columns for
dimensions and score_evolution 8. Reorder to target 20-column structure
