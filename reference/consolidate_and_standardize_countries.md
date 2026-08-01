# Consolidate and Standardize Country Names and Assign ISO Codes

Generic consolidation engine that applies country name consolidations,
removes diacritics, and assigns ISO 3-letter codes.

## Usage

``` r
consolidate_and_standardize_countries(
  combined_df,
  consolidation_mapping = NULL
)
```

## Arguments

- combined_df:

  Data frame with columns: year_n, country_en, and others

- consolidation_mapping:

  Data frame with columns: old_name, new_name, iso_code, reason

## Value

Data frame with standardized country names, ISO codes, and metadata
