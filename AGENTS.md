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
