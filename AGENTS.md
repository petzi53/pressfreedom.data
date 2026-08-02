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

### Dynamic Evaluation Contexts (cli, glue, etc.)

**Problem:** Functions used in cli/glue string interpolation (e.g., `{dplyr::n_distinct(...)}`) may fail if called from non-qualified contexts, due to R's environment scoping rules.

**Solution:** Pre-compute values with qualified calls, then interpolate the computed variables:

```r
# ❌ AVOID: Function call in interpolation string
cli::cli_inform("Count: {dplyr::n_distinct(df$col)}")

# ✅ DO: Pre-compute, then interpolate
n_distinct_col <- dplyr::n_distinct(df$col)
cli::cli_inform("Count: {n_distinct_col}")
```

This maintains package qualification throughout the code while avoiding environment scoping issues.

### dplyr NSE and R CMD check ("no visible binding for global variable")

**Problem:** Bare column names inside dplyr data-masking verbs (`mutate()`, `filter()`,
`arrange()`, `group_by()`, `case_when()`) trigger `R CMD check` NOTEs because static
analysis can't see that they resolve against the data frame at runtime.

**Solution:** Use the `.data` pronoun for data-masking verbs, quoted strings for
tidyselect verbs (`select()`, `rename()`, `relocate()`, `pull()`) — never
`utils::globalVariables()`, which is an unstructured, ever-growing list disconnected
from where each name is actually used:

```r
# Data-masking verb: use .data$col
df |> dplyr::filter(.data$year_n == 2024)

# Tidyselect verb: use a quoted string
df |> dplyr::select(-"keep_row")
```

Requires one-time `NAMESPACE` imports (in `R/utils.R`):

```r
#' @importFrom rlang .data
#' @importFrom rlang :=
NULL
```

`:=` needs its own import (not `.data$`) because it's a genuine `rlang` function used as
an infix operator for dynamic renames (`!!target := !!value`), not a column-name
resolution issue. These `@importFrom` tags are `NAMESPACE` metadata (like `Imports:` in
`DESCRIPTION`), not a violation of the "qualified calls" rule — they don't attach a
whole namespace or make other functions callable unqualified, and `:=`/`.data` can't be
written as `pkg::fn()` in the syntactic positions dplyr requires. Full rationale and
before/after examples: `.posit/assistant/docs/2026-07-30-data-pronoun-refactor.md`.

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
- **Posit Assistant Configuration (policy changed 2026-08-02):** `.posit/` (including `.posit/assistant/`) is now gitignored and untracked. It's ephemeral working scratch space — plans and docs written during a session, not a durable record. Anything worth keeping long-term (decisions, rationale, gotchas) gets promoted by hand into this file (AGENTS.md), which is the actual project memory and stays tracked. `.Rbuildignore` still excludes `.posit` from the built package (untracked files on disk still get bundled by `R CMD build` otherwise).
  - **Superseded approach:** earlier sessions tried to keep `.posit/assistant/` tracked in git for dev-history purposes, which required a custom Python pre-commit hook (`check_gitignore.py`) to guard against `.gitignore`/`.Rbuildignore` regressions that kept silently re-ignoring it. That hook was removed 2026-08-02 in favor of just gitignoring the directory outright — simpler, portable to other projects, no custom tooling to maintain. If you want to compare versions of a plan/doc across sessions, ask for a fresh document rather than relying on git history, or copy a snapshot somewhere outside the repo.

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

> **⚠️ ESSENTIAL: `score` is only comparable from 2013 onward.** RSF changed its
> scoring methodology in 2013; `score` (and, from 2022+, the dimension columns
> `political_context`/`economic_context`/`legal_context`/`social_context`/`safety`)
> for **2002–2012 use a different, non-comparable metric**. Any trend analysis,
> mean-by-year calculation, or cross-period comparison of `score` must filter to
> `year_n >= 2013` first — do not average or plot `score` across the 2002–2012 /
> 2013+ boundary.

#### Pre-Aggregation Checklist (run before ANY code that aggregates, averages, ranks, or plots `score`/dimension columns)

This checklist exists because the 2013 boundary has been violated multiple times
in past sessions — not because the rule was forgotten, but because it wasn't
re-checked at the point of writing aggregation code. Run through it explicitly,
every time, even mid-session, even when reusing objects that already look
filtered:

1. **Name the columns involved.** Is `score`, `political_context`,
   `economic_context`, `legal_context`, `social_context`, or `safety` part of
   this computation (directly, or via a derived object built from one of
   them)? If no -> checklist doesn't apply. If yes -> continue.
2. **Trace the data source, don't assume.** If building on an
   already-existing R object (e.g. something already in the environment like
   `yearly_mean`, `zone_means`, `eu_safety`, `eu_safety_change`,
   `global_safety_change`, `compare_df`, `germany_dims`,
   `germany_rank_global`), do not trust its name or prior usage as proof it's
   filtered. Re-derive it from `rwb_standardized` with an explicit
   `dplyr::filter(.data$year_n >= 2013)`, or inspect it
   (`range(obj$year_n)`) to confirm no rows predate 2013 before reusing it.
3. **Filter first, aggregate second.** The filter step must appear in the
   pipeline *before* any `group_by()`/`summarise()`/`mean()`/`arrange()` by
   rank on these columns — never filter after the fact as a correction.
4. **Dimension columns only exist from 2022+.** `political_context`,
   `economic_context`, `legal_context`, `social_context`, `safety` are `NA`
   for 2013–2021 (Period 2 had no dimensions) and non-comparable for
   2002–2012 (Period 1). A `year_n >= 2013` filter is necessary but not
   sufficient for dimension columns — also expect/handle `NA` for
   2013–2021 rather than silently dropping or zero-filling.
5. **State the filter in the output.** When presenting a result derived from
   these columns (text, table, or plot), say explicitly which years it
   covers (e.g., "2013–2026" or "2022–2026 for dimensions") so the boundary
   is visible to Peter, not just enforced silently in code.
6. **Before reusing a plotting object** (`p1`-`p7` or similar), check the
   data frame it was built from met steps 1–4 — a plot object doesn't carry
   forward a visible warning if its source data was wrong.

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

## Package Qualification Patterns ✅ REFINED

**Key Learning (2026-07-29):** Maintain package qualification while using dynamic evaluation contexts (cli, glue) by pre-computing values.

**Pattern:**
```r
# ✅ Compute with qualified calls
n_values <- dplyr::n_distinct(df$col)

# ✅ Then interpolate the variable
cli::cli_inform("Count: {n_values}")
```

This avoids both `library()` calls and environment scoping issues. See `.posit/assistant/docs/2026-07-29-package-qualification-with-cli.md` for full guidance.

**Commits:**
- 5d07014 — Applied pattern to standardize.R, removed library() from update.R

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

### Zone Column: French → English Translation ✅ COMPLETE (2026-07-31)

**What:** `zone` shipped with six French-language values inherited from RSF's
raw exports (`Afrique`, `Ameriques`, `Asie-Pacifique`, `EEAC`, `MENA`, `UE
Balkans`) -- the only non-English column in `rwb_standardized`. Translated to
English so every column is consistently English:

| Old (French) | New (English) |
|---|---|
| `Afrique` | `Africa` |
| `Ameriques` | `Americas` |
| `Asie-Pacifique` | `Asia-Pacific` |
| `EEAC` | `Eastern Europe & Central Asia` |
| `MENA` | `Middle East & North Africa` |
| `UE Balkans` | `EU & Balkans` |

**Where:** New "Step 3c" in `consolidate_and_standardize_countries()`
(`R/standardize.R`), applied *after* the existing Step 3b 2022 zone-anomaly
fix (which keys off the original French labels) and *after*
`repair_and_asciify()`. Mapping lives in `inst/extdata/zone_mapping.csv`
(same pattern as `consolidation_mapping.csv`). A hard validation check
(`cli::cli_abort()`) runs immediately after translation and fails the
pipeline if any non-`NA` `zone` value isn't one of the six approved English
names.

**Why this also fixes the recurring zone mojibake bug:** none of the six
English names contain diacritics, so there is nothing left for an
upstream Latin-1-as-UTF-8 encoding glitch to corrupt -- this closes the root
cause rather than continuing to rely on `repair_and_asciify()`'s
detect-and-repair heuristic for `zone` specifically (still used for
`country_en`).

**This is a breaking change to shipped data values** -- documented in
`NEWS.md`. Any code filtering on old French zone values (e.g. `zone ==
"MENA"`) needs updating.

**Files touched:** `inst/extdata/zone_mapping.csv` (new),
`R/standardize.R`, `vignettes/visualizing-trends.Rmd` (zone glossary
headers), `data/processed/rwb_standardized.rds`,
`data/rwb_standardized.rda`, `NEWS.md` (new).

### Package Logo: Sibling-Brand Redesign ✅ COMPLETE (2026-08-01)

**What:** `man/figures/logo.png` was redesigned so `pressfreedom.data` and
its companion Shiny app (`pressfreedom`, separate repo) read as a visual
family without being confusable with each other:

| Package | Badge shape | Badge color | Icon |
|---|---|---|---|
| `pressfreedom.data` (this repo) | Circle | Gold (`#E9C46A`, same as hex border) | White-on-teal 4x4 data-grid glyph (bold header row) |
| `pressfreedom` (Shiny app, separate repo) | Square | Orange (`#E76F51`) | White microphone |

Both badges sit at the same position/size (110px, centered in the empty
band between the title text and the world map -- roughly row 228 of the
518x600 hex canvas) on top of an identical gold-border/teal-background
choropleth world map hex, with the same white title text and font. The
shared map + border + text keeps the family resemblance; the differing
badge *shape and color* (not just icon content) keeps them distinguishable
even at favicon/thumbnail size, where fine icon linework is no longer
legible but a colored circle vs. square silhouette still reads clearly.

**Why a shape + color change, not just a different icon:** the original
approach (same map, only the small overlaid icon swapped between
microphone and data-grid) was legible at full size but collapsed to
indistinguishable at thumbnail scale -- the only differentiator was
exactly the detail that disappears first when downscaled. Putting each
icon on its own colored geometric plate gives a second, more robust
differentiator (silhouette) that survives scaling even when the icon
itself doesn't.

**Ownership going forward:**
- The **map + gold circle + data-grid** design belongs to
  `pressfreedom.data` -- this is now `man/figures/logo.png` in this repo.
- The **map + orange square + microphone** design belongs to the
  `pressfreedom` Shiny app -- handed off (with title text corrected from
  "pressfreedom.data" to "pressfreedom") for use in that package's separate
  repo. Do not reuse the orange-square-microphone combination for anything
  in this repo; do not reuse the gold-circle-grid combination in the
  `pressfreedom` app repo.

**Documented in:** `NEWS.md` (0.2.0, "Package logo" section).

**Icon attribution (hand-off requirement):** the microphone icon (used in
`logo-candidate-app-square.png`, now handed off to the `pressfreedom` app
repo) is a Flaticon icon requiring attribution under its free-tier license.
This package's own `logo.png` no longer uses the microphone (its gold
circle badge uses an original data-grid glyph, not a third-party icon), so
no attribution is owed here. The `pressfreedom` app repo's README **must**
include this credit wherever the logo is displayed:

```html
<a href="https://www.flaticon.com/free-icons/microphone" title="microphone icons">Microphone icons created by Magnific - Flaticon</a>
```

### CRAN Submission v0.2.0 ✅ SUBMITTED (2026-08-02)

**Status:** Package uploaded and verified, awaiting email confirmation link

**Submission details:**
- **Date/time:** 2026-08-02 14:02:36 UTC
- **Commit:** fbe31d0 (trimmed NEWS.md to standard concise style)
- **Command:** `devtools::release()` (interactive console submission)
- **Result:** ✅ "Package submission successful" — confirmation link sent to petzi53@gmail.com

**Post-submission actions taken:**
1. ✅ Committed `.Rbuildignore` update (excludes `CRAN-SUBMISSION` from build)
2. ✅ Committed `CRAN-SUBMISSION` metadata file (submission record)
3. ✅ Pushed both `main` and `v0.2.0` tag to `origin`

**Next steps (waiting on CRAN):**
- Check email for confirmation link (must click to activate submission)
- CRAN will begin automated checks within 24 hours
- Typical review time: 1-3 days
- Possible outcomes:
  - ✅ **Accept:** Package published to CRAN, visible in package archive
  - 🔄 **Fix & resubmit:** CRAN flags issues requiring rework
  - ❌ **Reject:** Fundamental issues; requires major redesign

**Estimated arrival timeline:**
- T+0 (2026-08-02): Submitted
- T+24h: CRAN automated checks run
- T+48-72h: Human reviewer processes
- T+72h+: Published (if accepted) or feedback email (if fixes needed)

**Notes:**
- `devtools::release()` is deprecated; future releases should use `usethis::use_release_issue()`
- Package is frozen at tag `v0.2.0` pending acceptance
- Do not push further changes until CRAN decision arrives

### pkgdown Website ✅ COMPLETE & VERIFIED LIVE (2026-08-01)

**Status:** Site scaffolded, deployed via GitHub Actions, GitHub Pages
enabled, and verified live at https://petzi53.github.io/pressfreedom.data/
(Phase 2 of the documentation strategy, see below). Plan closed out.
**Plan:** `.posit/assistant/plans/2026-08-01-pkgdown-website.md`

**What was done:**
- `_pkgdown.yml`: `url: https://petzi53.github.io/pressfreedom.data`,
  default Bootstrap 5 theme (no bootswatch override), navbar with
  "Get Started" (`getting-started` vignette) and "Articles" ->
  "Visualizing Trends" (`visualizing-trends` vignette).
- **Reference index intentionally lists only `rwb_standardized`.** All
  other functions are internal maintainer tooling (download/clean/combine/
  standardize pipeline, `update_rwb_data()`) and are not part of the
  public API -- they are not exported in `NAMESPACE` either, so this
  matches the package's actual design, not just a pkgdown display choice.
- `usethis::use_github_action("pkgdown")` added
  `.github/workflows/pkgdown.yaml`: builds on push to `main` and deploys
  to the `gh-pages` branch (folder `docs`) via
  `JamesIves/github-pages-deploy-action`. GitHub Pages must be enabled
  once on the repo (Settings -> Pages -> Deploy from branch -> `gh-pages`)
  after the first successful workflow run -- **manual one-time step, not
  done by this session.**
- `inst/CITATION` had a pre-existing syntax error (missing commas, a
  stray non-ASCII character in "Frontieres") that broke
  `pkgdown::build_site()` entirely (it installs the package into a temp
  library, which parses `inst/CITATION`); fixed as part of getting the
  build to run, independent of pkgdown-specific config.
- `DESCRIPTION` `URL` field: added the pkgdown site URL alongside the
  existing GitHub repo URL (`pkgdown::build_site()`'s URL check requires
  this).
- **Known pkgdown limitation (2.2.1) -- no config to exclude root
  `.md` files from the home page:** `build_home()` auto-renders every
  `*.md` in the repo root (and `.github/`) except README/LICENSE/NEWS,
  which means `AGENTS.md` (this file -- internal memory/working notes,
  not public-facing) gets published as `AGENTS.html` with no way to
  suppress it via `_pkgdown.yml`. Worked around by adding a
  `rm -f docs/AGENTS.html docs/AGENTS.md` step to
  `.github/workflows/pkgdown.yaml` right after the build step, before
  deploy. If a future pkgdown version adds a proper exclude option
  (check `home:` config docs), switch to that instead of the rm hack.
- `pkgdown/favicon/` (favicons generated from `man/figures/logo.png` via
  realfavicongenerator.net) is committed per pkgdown convention, to avoid
  an external API call on every rebuild.
- `docs/` (the rendered site) is gitignored/buildignored -- built fresh
  by CI on every push, never committed manually.

**Not done in this pass (deliberately out of scope per plan):**
- No footer link to the companion Quarto book yet (placeholder comment
  left in `_pkgdown.yml`) -- add once that separate repo's site is live.

**GitHub Pages activation gotcha (2026-08-01):** the `gh-pages` branch does
NOT exist until `.github/workflows/pkgdown.yaml` runs successfully at least
once on a push to `main` -- it's created automatically by
`JamesIves/github-pages-deploy-action`, not by hand. If Settings -> Pages ->
"Deploy from a branch" only shows `main` (no `gh-pages` option), that means
the workflow hasn't run yet (commits pending push, or the Actions run
failed/hasn't completed). Fix: `git push origin main`, confirm the
"pkgdown.yaml" Actions run succeeds, then set Pages to branch `gh-pages`,
folder `/ (root)` (not `docs` on `main` -- the built site only lives on
`gh-pages`, `docs/` on `main` is never committed).

**`ggbump` archived-from-CRAN gotcha (2026-08-01):** the first Actions run
failed at the `pak` dependency-install step because `visualizing-trends.Rmd`
uses `ggbump` for a bump chart, and `ggbump` was archived from CRAN on
2025-12-04 -- `pak` can no longer resolve it as a regular CRAN dependency.
Fixed by adding `Remotes: davidsjoberg/ggbump` to `DESCRIPTION` so `pak`
installs it from GitHub instead. Verified locally with
`pak::pkg_deps_tree()` before pushing. If other vignette dependencies get
archived from CRAN in the future, the same `Remotes:` pattern applies.

**GitHub Pages activation and live verification (2026-08-01):** Peter
enabled Settings -> Pages -> Deploy from branch `gh-pages`, folder
`/ (root)`, after the `ggbump` fix let the workflow run succeed. Site
confirmed live and fully functional:
- Homepage renders (https://petzi53.github.io/pressfreedom.data/)
- Both vignettes (`getting-started`, `visualizing-trends`) return 200
- Reference page (`rwb_standardized`) returns 200
- `AGENTS.html` correctly returns 404 -- confirms the CI `rm -f` workaround
  strips the internal memory file from the deployed site as intended

This closes out `.posit/assistant/plans/2026-08-01-pkgdown-website.md`.
Remaining pkgdown-adjacent work (footer link to the Quarto book) is
tracked separately under "Next Steps" and is not part of this plan's scope.

### R CMD Check Fixes ✅ COMPLETE & COMMITTED

**Status:** All 5 actionable issues fixed (2026-07-29)  
**Commit:** a56964b — Chore: Fix R CMD check issues

**Issues Fixed:**
1. ✅ Removed unused `verbose` parameter from `download_rwb_data()` call in `update_rwb_data()`
2. ✅ Escaped non-ASCII characters (Unicode escapes \uXXXX) in `R/standardize.R` (Côte, Türkiye, Curaçao, etc.)
3. ✅ Replaced em-dashes with ASCII dashes in `R/update.R` documentation
4. ✅ Added missing imports to DESCRIPTION: fs, glue, purrr, tibble
5. ✅ Created comprehensive README.md with usage examples and API documentation

**Remaining Warnings (Harmless):**
- Icon file in git history (will disappear on next push; already in .gitignore)
- data/cleaned/ and data/processed/ in 'data' directory (intentional design for auditability)
- "No visible binding" warnings for dplyr variables (expected with NSE pipelines)

**Test Results:**
- Package loads cleanly ✓
- All dependencies declared ✓
- Non-ASCII code characters removed ✓
- Portable file names ✓
- All roxygen documentation valid ✓

### Non-ASCII Prevention Infrastructure v2 (root cause fix) - COMPLETE & COMMITTED (2026-07-30)

**Status:** v1 hook was silently broken (false positives on plain ASCII quotes, never version-controlled). Replaced with a robust Python-based checker.
**Superseded doc:** `.posit/assistant/docs/2026-07-29-non-ascii-prevention-policy.md` (kept for history)
**Current doc:** `.posit/assistant/docs/2026-07-30-non-ascii-prevention-v2.md`

**What was wrong with v1:** the "smart quotes" bash character class `["'']` had
silently degraded into matching plain ASCII quotes, flagging almost every normal
R string literal. This trained the habit of `git commit --no-verify`, which meant
real violations could slip through unnoticed. The hook also only lived in
`.git/hooks/` (never tracked by git), so a fresh clone had no protection at all.

**v2 solution:**

1. **`.githooks/check_ascii.py`** - core scanner, pure Python. Flags any
   character with `ord(ch) > 127` (numeric comparison, nothing for an editor
   or shell to corrupt) rather than matching an enumerated, hand-typed list of
   "bad" characters. Reports line/column, Unicode name, and a suggested ASCII
   replacement for each violation. Checks staged content via `git show :path`
   so partially-staged files are validated correctly.
2. **`.githooks/pre-commit`** - thin wrapper (`exec python3 ... --staged`),
   versioned in the repo. Enable per-clone with:
   ```bash
   git config core.hooksPath .githooks
   ```
3. **Scope:** only `*.R`, `*.Rmd`, `*.Rnw`, `*.Rd`, `*.qmd`, `DESCRIPTION`,
   `NAMESPACE` - i.e. only what actually matters for R CMD check/CRAN.
   Explicitly excludes `inst/extdata/` (raw RSF data, legitimately
   non-ASCII), `data-raw/`, `data/`, `renv.lock`, and `.posit/` (internal
   planning notes, not shipped with the package).

**Verification:** false-positive regression test (plain ASCII quotes pass),
true-positive test (en-dash/em-dash/curly quotes/accents/arrows all caught
with diagnostics), end-to-end `git commit` block test, and a full-codebase
scan that surfaced and fixed real pre-existing violations in `R/clean.R`,
`R/data.R`, and stale generated `.Rd` files that v1's narrow character list
had missed entirely.

**Coding standard (unchanged):**
- Use `2002-2026` (ASCII hyphen), not en-dash or em-dash
- Use `Phase A - Download` (ASCII dash)
- Use `->` for arrows, not the Unicode arrow character
- Use straight quotes `"..."`, not curly quotes

### Documentation & Publishing Strategy ✅ PLANNED & APPROVED (2026-07-30)

**Status:** Multi-level documentation architecture approved, implementation plan created

#### Phase 1: Package Vignette ✅ COMPLETE & COMMITTED (2026-07-30)

**Deliverable:** `vignettes/pressfreedom-introduction.Rmd`  
**Commit:** 8e2f351  
**Word count:** ~3,200 words  
**Status:** All code examples tested and executable

**Sections completed:**
- Introduction & motivation (why the package exists)
- Installation & quick start (loading data, exploring)
- Understanding the data structure (columns, data types, key notes)
- Common usage patterns (6 detailed examples with code)
- Annual updates (update_rwb_data() function, manual control)
- Working with analysis packages (ggplot2, broom, tsibble examples)
- Data quality notes (missing years, country consolidation, territorial variants, ISO codes)
- FAQ & troubleshooting (7 common questions)

**Dependencies added to DESCRIPTION:**
- Added `knitr` and `rmarkdown` to Suggests (required for vignette rendering)

**Implementation notes:**
- All R code examples execute without errors
- Vignette builds cleanly via `devtools::build_vignettes()`
- ASCII-only characters per non-ASCII prevention policy
- Examples cover both basic and intermediate usage patterns

**Next phase:** pkgdown website setup (Phase 2)

**Four-level documentation approach:**

1. **Package Vignette** (`vignettes/pressfreedom-introduction.Rmd`)
   - File: `vignettes/pressfreedom-introduction.Rmd`
   - Purpose: Quick-start guide for package users
   - Audience: CRAN users, R practitioners
   - Content: Installation, data overview, common patterns, annual updates
   - Scope: ~2,500-3,500 words, 15-20 min read

2. **pkgdown Website** (https://petzi53.github.io/pressfreedom.data)
   - Config: `pkgdown/_pkgdown.yml`
   - Purpose: Official public documentation
   - Audience: CRAN users, GitHub visitors, researchers
   - Includes: README (home), function reference, vignette, optional articles
   - Deploy: GitHub Actions auto-deploy to GitHub Pages

3. **Quarto Book** (https://petzi53.github.io/pressfreedom.data-book)
   - Repo: Separate GitHub repo `pressfreedom.data-book`
   - Purpose: Deep-dive on design, decisions, failures, and AI collaboration
   - Audience: Developers, data engineers, AI enthusiasts, learning community
   - Content: 10 chapters (~15,000-20,000 words)
     - Ch. 01: Introduction & Context
     - Ch. 02-05: Phases A-D (design, failures, iterations)
     - Ch. 06: Orchestration (update_rwb_data design)
     - Ch. 07: Posit Assistant collaboration (summaries + key decisions)
     - Ch. 08: QA & Validation
     - Ch. 09: Appendix (full session transcripts as reference)
     - Ch. 10: Epilogue (reflections, lessons, next steps)
   - Deploy: GitHub Actions auto-deploy to GitHub Pages

4. **Blog Posts** (https://www.peter-baumgartner.net/)
   - Platform: Personal blog (repo: https://github.com/petzi53/petzi53.github.io/)
   - Purpose: Standalone articles for broader audience
   - Topics (priority order):
     1. "Building a Data Pipeline for 24 Years of Evolving Data"
     2. "How I Used AI to Build a Production R Package" (AI-focused, consider Dev.to)
     3. "Consolidating 200+ Country Names: The Data Cleaning Problem"
     4. (Optional) "Press Freedom Trends 2002-2026: A First Look"
   - Scope: 1,500-2,500 words each, linked to pressfreedom.data docs

**Timeline (6 weeks):**
- Week 1: Vignette + pkgdown setup
- Week 2: Quarto book repo setup + Ch. 01
- Weeks 3-5: Book Ch. 02-10 (parallel with blog posts)
- Week 6+: Polish, deploy, publish

**Key decisions:**
- ✅ Vignette & pkgdown: In pressfreedom.data repo
- ✅ Book: Separate GitHub repo (independent release cycles)
- ✅ Blog: Personal blog at peter-baumgartner.net
- ✅ Transcripts: Summaries + key decisions in chapters; full transcripts in appendix (separate `.qmd` files) for reference
- ✅ Vignette-Book links: Vignette standalone (no links); after book launch, add one link to book home in pkgdown footer
- ✅ Book appendix: Index chapter (Ch. 09) with links to `appendix/*.qmd` transcript files
- ✅ Dev.to cross-posting: Decision postponed; revisit after vignette complete
- ✅ Timeline: Keep 6-week target; reassess after Week 1 vignette completion

**Documentation files:**
- `.posit/assistant/plans/2026-07-30-1310-documentation-strategy.md` — Strategic overview & product definitions
- `.posit/assistant/plans/2026-07-30-1400-implementation-plan.md` — Detailed task list, timeline, checklist

### Documentation

- `README.md` — User-facing package documentation with quick start, API reference, and annual update workflow
- `.posit/assistant/docs/2026-07-29-non-ascii-prevention-policy.md` — Non-ASCII prevention policy and infrastructure
- `2026-07-28-phase-b-normalization.md` — Phase B details
- `2026-07-28-phase-c-combination.md` — Phase C completion
- `2026-07-28-phase-d-standardization.md` — Phase D plan
- `2026-07-28-workflow.md` — Complete workflow overview
