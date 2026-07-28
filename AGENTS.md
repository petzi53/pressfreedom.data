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
| **D** | Standardize countries | `rwb_combined.rds` | `rwb_standardized.rds` | Ready |

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

### Phase D: Standardization (NEXT)

**Input:** `rwb_combined.rds`  
**Output:** `rwb_standardized.rds`

**Planned scope:**
1. Normalize country names (remove accents)
2. Handle special countries (Taiwan, Kosovo, Palestine, etc.)
3. Assign ISO 3-letter codes via `countrycode`
4. Validate output

**Function:** `standardize_rwb_countries()` (to create)

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
