# Resolve Missing-Trailing-Zero Score Scaling

RSF's 2013+ exports store score/dimension percentages (0-100, 2 implied
decimal places) as bare digit strings with no decimal point (e.g. "9189"
means 91.89). Values ending in one or two zeros have those trailing
zeros silently dropped somewhere in RSF's own export pipeline (e.g.
"844" means 84.40, not 8.44; "87" means 87.00, not 0.87), which is
indistinguishable from a genuinely low sub-10 score for the worst-ranked
countries (e.g. "46" for a rank-180 country can legitimately mean 0.46).

## Usage

``` r
resolve_percent_scaling(raw_chr, rank_chr)
```

## Arguments

- raw_chr:

  Character vector. Raw digit strings from the source CSV (no decimal
  point; may have a leading "-" for Period 1 legacy values).

- rank_chr:

  Character vector, same length as \`raw_chr\`. The corresponding rank
  column, used to disambiguate short values by comparing against
  neighboring, unambiguous (4+ digit) values at nearby ranks (scores are
  approximately monotonic in rank).

## Value

Numeric vector of resolved percentages (0-100 scale).

## Details

Values with 4 or more digits are unambiguous ("confirmed"): a 4-digit
value is divided by 100 (2 implied decimals), and a small number of 2025
rows have 5-digit values (RSF apparently breaks near-tied ranks with a
third decimal place, e.g. "65487" means 65.487, not 654.87), so n-digit
confirmed values are divided by \`10^(n_digits - 2)\` generally. For
shorter (2-3 digit) values, two candidates are computed: right-padding
with zeros to 4 digits before dividing by 100 (the "dropped trailing
zero" interpretation), and dividing the raw digits by 100 directly (the
"already complete, genuinely low score" interpretation). The candidate
closer to a rank-based linear interpolation of neighboring confirmed
values is selected. Missing rank or missing value inputs fall back to
the zero-padded interpretation.
