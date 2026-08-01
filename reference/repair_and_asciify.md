# Repair Mojibake and Normalize Text to ASCII

Repairs character strings that were corrupted by one or more rounds of
incorrect Latin-1-as-UTF-8 decoding (a recurring artifact in RSF's
source files), then transliterates any remaining accented characters to
their closest ASCII equivalent. Detection and repair are byte-level and
generic, so this handles corruption depth (single or double mojibake)
and new corrupted values automatically, without needing a
hand-maintained list of known-bad strings.

## Usage

``` r
repair_and_asciify(x, max_passes = 3)
```

## Arguments

- x:

  Character vector, potentially containing mojibake and/or accented
  characters

- max_passes:

  Maximum number of mojibake-repair passes to attempt (guards against
  pathological input; real-world cases resolve in 1-2 passes)

## Value

Character vector, ASCII-only
