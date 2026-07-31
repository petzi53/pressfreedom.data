# Archived: Working with Analysis Packages examples

**Context:** These examples originally lived in the
`vignettes/pressfreedom-introduction.Rmd` vignette under "Working with Analysis
Packages." They were removed from shipped documentation (see
`.posit/assistant/plans/2026-07-30-2339-plan.md`, Q11) because they demonstrate
generic patterns (a line chart, a linear model, a tsibble conversion) rather than
anything specific to this package, and the vignette rewrite replaces them with
purpose-built charts. Kept here for personal reference.

## Visualization with ggplot2

```r
library(ggplot2)

# Plot press freedom trends for selected countries
rwb_standardized |>
  dplyr::filter(country_en %in% c("Germany", "France", "United States", "China")) |>
  ggplot(aes(x = year_n, y = score, color = country_en)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Press Freedom Trends",
    x = "Year",
    y = "Score (0=most free, 100=least free)",
    color = "Country"
  ) +
  theme_minimal()
```

## Regression Analysis with broom

```r
library(broom)

# Does a country's rank improve or decline?
germany_model <- rwb_standardized |>
  dplyr::filter(country_en == "Germany", !is.na(score)) |>
  lm(score ~ year_n, data = _)

broom::tidy(germany_model)
```

## Time Series with tsibble

```r
library(tsibble)

# Convert to tsibble for time series analysis
ts_data <- rwb_standardized |>
  dplyr::filter(country_en == "Germany") |>
  dplyr::select(year_n, score) |>
  tsibble::as_tsibble(index = year_n)

ts_data
```
