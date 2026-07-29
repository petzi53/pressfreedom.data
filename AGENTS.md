# pressfreedom.data — AI Agent Preferences

**Author:** Peter Baumgartner (petzi53@gmail.com)  
**Project:** pressfreedom.data  
**Location:** ~/Documents/Meine-Repos/pressfreedom.data

---

## R Coding Style

- **Pipe:** Base R `|>` (never magrittr `%>%`)
- **Qualified calls:** Use `pkg::fn()` in scripts and functions
- **Paths:** Always `here::here()` — never hardcoded absolute paths
- **Random seeds:** Choose randomly between 1–10,000 (avoid 42, 123, 1234, etc.)
- **Package repos:** Never set `repos` in `install.packages()`
- **Meta-packages:** Import only what's needed; avoid `library(tidyverse)` in favor of specific packages

### Comments

- Brief and purposeful — explain *why*, not *what*
- Always comment regex patterns
- In pipelines, place comments on the line *before* relevant code
- Comment out initial `library()` calls so users know what to install
- Use qualified calls (`pkg::fn()`) in code instead
- When using tidymodels: comment extensively as it's a newer approach for this author

### ggplot2

- Default visualization tool for all plots
- No `coord_flip()` — flip aesthetic mappings instead
- No arbitrary `fill`/`color` unless explicitly requested
- No dual encoding (same variable mapped to two aesthetics)
- First pass: minimally sufficient; no extra theming or `geom_smooth()` unless asked
- Data as first argument: `ggplot(df, aes(...))` not `df |> ggplot(aes(...))`

---

## Package Development

- **License:** MIT (default)
- **Version control:** Git + GitHub (https protocol)
- **Install method:** `devtools::load_all()` during development
- **Data storage:** `.rds` files in `data/<subfolder>/`

---

## Core Packages (commonly used)

tidyverse (specific imports), here, fs, purrr, rlang, yaml, readr, stringr, tidymodels, bslib, devtools, usethis

---

## Quarto Conventions

- **Output:** Quarto website → `docs/` → GitHub Pages
- **Freeze:** auto
- **Theme:** sandstone + brand; highlight: atom-one
- **Code options:** `code-fold: true`, `code-summary: "Show/hide the code"`
- **File naming:** kebab-case.qmd
- **Function naming:** snake_case

### Data frame printing in Quarto

Always use explicit print commands to avoid truncation:
- `print(df, n = Inf)` for full data frames
- `knitr::kable(df)` for formatted HTML tables
- `dplyr::glimpse(df)` for wide datasets

---

## Workflow

- **Personas:** Default to Data Scientist (unless explicitly requested: Bayesian or Coder)
- **Memory files:** This file serves as the project-level memory
- **Do not reference:** Contents of `_archive/` folder unless explicitly asked

---

## pressfreedom.data Project

### Overview

R package for downloading, cleaning, and standardizing press freedom data from Reporters Sans Frontières (RSF, 2002–2026).

### Data Structure

Dataset spans 24 years (2002–2026, with 2011 intentionally missing). Three distinct periods due to RSF methodology changes:

| Period | Years | Characteristics |
|--------|-------|-----------------|
| **1** | 2002–2012 | 16 columns; non-comparable scores; multiple language variants |
| **2** | 2013–2021 | 16 columns; comparable scores (0–100); same structure as Period 1 |
| **3** | 2022–2026 | 22–25 columns; dimensions added (Political, Economic, Legal, Social, Safety); year-specific score naming |

### Workflow: Four Phases

| Phase | Task | Input | Output | Status |
|-------|------|-------|--------|--------|
| **A** | Download | URLs | `data/raw/` (24 CSV files) | ✅ Complete |
| **B** | Normalize columns | `data/raw/` | `data/cleaned/period_X/` (25 RDS) | ✅ Complete |
| **C** | Combine periods | `data/cleaned/period_X/` | `data/processed/rwb_combined.rds` | ✅ Complete |
| **D** | Standardize countries | `rwb_combined.rds` | `rwb_standardized.rds` | ✅ Complete |

### Phase B: Normalization

**Output:** 25 RDS files normalized to 20-column unified structure
```
year_n, iso, country_en, score, rank,
political_context, rank_pol, economic_context, rank_eco,
legal_context, rank_leg, social_context, rank_soc,
safety, rank_saf, zone, rank_n_1, rank_evolution,
score_n_1, score_evolution
```

**Key transformations:**
- Column name normalization
- Factor → character conversion (iso, country_en, zone)
- Decimal separator conversion (comma → period)
- Special case handling:
  - 2012: "2011-12" → year 2012
  - 2025–2026: "Score YYYY" → "score"
  - 2024+: Drop "Situation" column
  - 2023–2026: Apply decimal conversion to score_evolution

**Functions:** `clean_period_1/2/3()`, `clean_rwb_single()`, `clean_all_rwb_years()`

### Phase C: Combination

**Output:** `data/processed/rwb_combined.rds`
- 4,200 rows (all periods merged)
- 20 columns (unified)
- Sorted by year_n, country_en

**Function:** `combine_cleaned_periods()` in `R/combine.R`

### Phase D: Standardization ✅ COMPLETE & COMMITTED

---

## Update Automation ✅ IMPLEMENTED & TESTED

**Status:** Specialized yearly update function complete, tested, and committed  
**File:** `R/update.R` (646 lines)  
**Exports:** `update_rwb_data()`, `print.rwb_update()`  
**Documentation:** `man/update_rwb_data.Rd`, `man/print.rwb_update.Rd`  
**Implementation Report:** `.posit/assistant/docs/2026-07-29-update-function-implementation.md`  
**Commits:** 1c9133f, 0e3b312, 71a7c4b, 4588314, 79c17e9  
**Verification:** ✅ All checks passed (2026-07-29)

### Function: `update_rwb_data()`

**Purpose:** Orchestrates full yearly update workflow in a single function call.

**Signature:**
```r
update_rwb_data(
  years = NULL,           # Auto-detect missing years
  download = TRUE,        # Phase A: download
  clean = TRUE,          # Phase B: clean
  combine = TRUE,        # Phase C: combine (always required)
  standardize = TRUE,    # Phase D: standardize (always required)
  validate = TRUE,       # Run validation checks
  verbose = TRUE,        # Print progress
  auto_commit = TRUE     # Auto-commit to git
)
```

**Workflow:**
1. **Detection:** Auto-detect missing years via `get_years_to_download()`
2. **Phase A (Download):** Downloads only new years → `inst/extdata/`
3. **Phase B (Clean):** Cleans newly downloaded years → `data/cleaned/period_X/`
4. **Phase C (Combine):** Recombines all periods, recalculates evolution columns → `data/processed/rwb_combined.rds`
5. **Phase D (Standardize):** Re-standardizes all data, applies consolidation rules → `data/processed/rwb_standardized.rds`
6. **Export:** Exports to package format → `data/rwb_standardized.rda`
7. **Validation:** Checks row counts, duplicates, required columns, consolidation count
8. **Git Commit:** Auto-commits changes with descriptive message

**Returns:** Invisible list with class `rwb_update` containing:
- `status`: "success" | "partial" | "failed"
- `years_downloaded`: Years downloaded
- `years_cleaned`: Years cleaned
- `rows_before`/`rows_after`: Row counts
- `consolidations_applied`: Count of consolidation rules applied
- `validation_passed`: TRUE if all checks pass
- `messages`: Progress messages
- `git_commit`: Commit hash (if auto-committed)

**Error Handling (from plan decisions):**
- Download fails → Aborts with error
- Cleaning fails → Aborts, reports which year failed
- Combine/Standardize fails → Aborts
- Validation fails → Reports issues; doesn't abort
- Git commit fails → Reports warning; doesn't abort

**Example Usage:**
```r
# Minimal yearly update
result <- update_rwb_data()
print(result)

# Test without download
result <- update_rwb_data(download = FALSE, clean = FALSE)

# Manual years (not auto-detected)
result <- update_rwb_data(years = c(2027))
```

### Design Decisions (from plan approval)

1. ✅ **Validation:** Yes, validate CSVs before cleaning
2. ✅ **Backup:** Creates backup implicitly (previous RDS only overwritten after success)
3. ✅ **Auto-commit:** Yes, with descriptive messages + report changes
4. ✅ **Consolidation changes:** Always run Phase D (fast anyway)
5. ✅ **Error recovery:**
   - Download fails → Abort with error
   - Cleaning fails → Abort, report year that failed
6. ✅ **No dev/ restore:** Not needed (function is the interface now)

### Why No {targets}?

- Linear 5-step sequence (no parallelization benefit)
- Annual frequency (low iteration rate)
- Fast execution (~30 seconds)
- No DAG complexity needed
- Orchestration is explicit in R code
- Specialized function is simpler and more maintainable

### Phase D: Standardization ✅ COMPLETE & COMMITTED

**Input:** `rwb_combined.rds` (4,200 rows, 207 countries)  
**Output:** `rwb_standardized.rds` (4,192 rows, 191 countries)  
**Status:** Git commits a9d381c, 84b5102, c85adeb — Phase D functions, dataset, dependencies fixed

**Completed scope:**
1. ✅ Consolidated 14 country name pairs (official changes + RSF methodology)
2. ✅ Handled territorial variants (Israel, US, Cyprus)
3. ✅ Assigned ISO 3-letter codes (100% coverage)
4. ✅ Applied ASCII normalization (removed accents)
5. ✅ Validated output (all checks pass)
6. ✅ Committed all changes with comprehensive documentation

**Key Results:**
- Consolidated countries: Czech Republic→Czechia, Turkey→Turkiye, Ivory Coast→Cote d'Ivoire, etc.
- Territorial variants: Deleted 8 rows (Israel occupied, US in Iraq/outside); consolidated Israel/US variants
- Cyprus distinction: Kept Cyprus (CYP) and Northern Cyprus (CXX) separate (different entities)
- Consolidation flag: 246 rows marked as consolidated; full audit trail preserved
- ISO codes: All 4,192 rows have valid ISO codes
- Dataset available: `rwb_standardized` exported in both `.rds` and `.rda` formats

**Functions Created & Exported:**
- `R/standardize.R`: `consolidate_and_standardize_countries()`, `standardize_rwb_countries()`, `validate_standardization()` (requires {countrycode}, {dplyr}, {stringr}, {cli})
- `R/data.R`: `rwb_standardized` dataset documentation
- `inst/extdata/consolidation_mapping.csv`: Maintainable consolidation pairs (updates only when RSF methodology changes)

**Package Dependencies Fixed (Commit c85adeb):**
- ✅ Added {countrycode}, {dplyr}, {stringr}, {cli} to Imports (were missing or in Suggests)
- ✅ Removed unused {targets} from Suggests
- Exported functions now have all required dependencies declared

**Documentation:**
- `2026-07-29-phase-d-standardization-report.md` — Comprehensive standardization report

### Key Design Decisions

- **Early combination:** Combine in Phase C (not after standardization) for single standardization pass
- **Period organization:** Separate period_1/2/3 directories in Phase B output for auditability
- **20-column structure:** Unified across all periods (NA for unavailable data)
- **Character not factor:** User preference; avoids level ordering issues
- **Keep raw files:** Auditability; always preserve original data

### Documentation

- `2026-07-28-phase-b-normalization.md` — Phase B details
- `2026-07-28-phase-c-combination.md` — Phase C completion
- `2026-07-28-phase-d-standardization.md` — Phase D plan
- `2026-07-28-workflow.md` — Complete workflow overview
