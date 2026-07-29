# Maintaining Package Qualification with Dynamic Evaluation

**Date:** 2026-07-29  
**Problem:** How to use package-qualified function calls with cli/glue string interpolation  
**Solution:** Pre-compute values, then interpolate

---

## The Challenge

Your preferred style uses explicit package qualification:
```r
dplyr::n_distinct(df$col)
stringr::str_replace(x, pattern, replacement)
countrycode::countrycode(country, ...)
```

However, when these functions are called inside cli/glue string interpolation, R's environment scoping can cause them to fail:

```r
# ❌ This fails in certain contexts
cli::cli_inform("Unique values: {dplyr::n_distinct(df$col)}")
```

**Why?** cli's interpolation evaluates expressions in a special context where package qualification may not resolve correctly.

---

## The Solution: Pre-compute Values

Instead of calling functions within the interpolation string, compute the values first, then interpolate:

```r
# ✅ This always works
n_distinct_col <- dplyr::n_distinct(df$col)
cli::cli_inform("Unique values: {n_distinct_col}")
```

### Applied Example (from standardize.R)

**Before (problematic):**
```r
cli::cli_alert_info("Unique countries (before): {n_distinct(combined$country_en)}")
cli::cli_alert_info("Unique countries (after): {n_distinct(standardized$country_en)}")
```

**After (correct):**
```r
n_countries_before <- dplyr::n_distinct(combined$country_en)
n_countries_after <- dplyr::n_distinct(standardized$country_en)

cli::cli_alert_info("Unique countries (before): {n_countries_before}")
cli::cli_alert_info("Unique countries (after): {n_countries_after}")
```

---

## Benefits of This Pattern

| Aspect | Benefit |
|--------|---------|
| **Package qualification** | Maintained throughout code |
| **No library() calls** | No pollution of function environment |
| **Clarity** | Intermediate values have explicit names |
| **Testability** | Computed values can be inspected before messaging |
| **Debugging** | Stack traces show where values came from |
| **Consistency** | Same approach works with cli, glue, stringr, etc. |

---

## When This Pattern Applies

Use pre-computation with:
- `cli::cli_inform()`
- `cli::cli_alert_*()`
- `glue::glue()`
- `stringr::str_glue()`
- Any other dynamic evaluation context

**Don't need it for:**
- Regular function calls: `dplyr::filter(df, col == val)`
- Piped operations: `df |> dplyr::select(col1, col2)`
- Conditional logic: `if (dplyr::n_distinct(df$col) > 10) { ... }`

---

## Rule of Thumb

**If the function call is inside `{}`** in a cli/glue string, **pre-compute it first.**

---

## Example: Complete Workflow

```r
# Load data
df <- readRDS("data/mydata.rds")

# Compute metrics with qualified calls
n_rows <- nrow(df)
n_cols <- ncol(df)
n_distinct_countries <- dplyr::n_distinct(df$country)
n_missing_values <- sum(is.na(df$value))

# Message with interpolated values
cli::cli_inform("Dataset summary:")
cli::cli_alert_info("Rows: {n_rows}")
cli::cli_alert_info("Columns: {n_cols}")
cli::cli_alert_info("Distinct countries: {n_distinct_countries}")
cli::cli_alert_info("Missing values: {n_missing_values}")
```

All function calls are qualified, no `library()` needed, and cli interpolation works perfectly.

---

## Git History

- **Commit 5d07014** — Applied this pattern to standardize.R and removed library() from update.R
- **Commit 1c9133f** — Original update_rwb_data() function (used library() before pattern was established)
- **Commit 0e3b312** — Fixed validation logic in same file

---

## References

- AGENTS.md — Updated with guidance on dynamic evaluation contexts
- R/standardize.R (lines 161-183) — Live example
- R/update.R — Updated to use only requireNamespace() checks, no library()
