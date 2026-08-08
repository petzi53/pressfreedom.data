# Standardize RSF Country Data

Main wrapper function for Phase D standardization pipeline. Loads
combined data, applies consolidations, assigns ISO codes, and saves
standardized output.

## Usage

``` r
standardize_rwb_countries(input_file, output_file, mapping_file = NULL)
```

## Arguments

- input_file:

  Path to combined RDS file. Required (no default) so the function never
  reads from a package or home directory implicitly.

- output_file:

  Path to write standardized RDS file. Required (no default) so the
  function never writes to a package or home directory implicitly.

- mapping_file:

  Path to consolidation mapping CSV

## Value

Invisibly returns the path to the output file
