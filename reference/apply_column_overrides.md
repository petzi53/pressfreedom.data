# Apply Column Name Overrides to a Mapping

Updates a period column mapping (target_col -\> raw_col) with
user-provided overrides, so a renamed raw column can still be found.

## Usage

``` r
apply_column_overrides(mapping, overrides)
```

## Arguments

- mapping:

  List. Period column mapping, as returned by \`get_period_mapping()\`.

- overrides:

  Named list as returned by \`load_column_overrides()\` (\`target_col =
  "actual_col"\`), or \`NULL\`.

## Value

The (possibly updated) mapping list.
