# Get Years That Need Downloading

Compares available CSV files in the input directory against a full list
of years to identify which years are missing. Automatically excludes
2011 (no official RSF data).

## Usage

``` r
get_years_to_download(input_dir = "inst/extdata", all_years = 2002:2026)
```

## Arguments

- input_dir:

  Character. Directory path containing downloaded CSV files. Defaults to
  `"inst/extdata"`.

- all_years:

  Integer vector. All years to check for. Defaults to `2002:2026`.

## Value

Integer vector of years that don't have corresponding CSV files. Returns
empty vector if all years are present.

## Details

This is a utility function useful for incremental updates. For example,
when a new year of data becomes available at RSF, use this function to
detect which years need downloading without re-downloading existing
data.

Note: Year 2011 is never included in the returned vector, even if it's
in the `all_years` range.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check which years are missing locally
missing_years <- get_years_to_download()
missing_years
} # }
```
