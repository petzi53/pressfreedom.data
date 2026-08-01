# Plan: De-duplicate README.md vs. vignettes/getting-started.Rmd

## Context

Read in full: `README.md` (163 lines), `vignettes/getting-started.Rmd` (205
lines), and the `@format`/`@details` roxygen block for `rwb_standardized` in
`R/data.R`. There is no `inst/CITATION` file yet.

## Diagnosis: what each document currently is vs. what it should be

R community convention (tidyverse/rOpenSci style) treats these as
**different documents for different moments**, not two drafts of the same
content:

| Document | Read when | Job |
|---|---|---|
| `README.md` | Browsing GitHub/CRAN *before* installing | Elevator pitch + "how do I install this" + one minimal example + pointers onward. Should be skimmable in under a minute. |
| `vignette("getting-started")` | *After* installing, inside R (`vignette(...)`) or on the pkgdown "Get started" nav tab | The tutorial: motivation/why, a fuller walkthrough, FAQ, data-quality caveats. Assumes the reader already has the package. |
| `?rwb_standardized` (`R/data.R` roxygen `@format`/`@details`) | Looking up what a specific column means | The single canonical data dictionary. |

Right now, three sections are duplicated nearly verbatim across two or three
places, which is the redundancy you noticed:

1. **Installation** — appears in both README and the vignette. Vignettes are
   read from inside an R session where the package is already loaded
   (`library(pressfreedom.data)` runs at the top), so repeating install
   instructions there is against convention — nobody reads a vignette to
   find out how to install the package they're currently running.
2. **"Why This Package?" (vignette) vs. "Overview" (README)** — both describe
   the 4-phase pipeline and the periods/consolidation/ISO-code story, just at
   different lengths. Convention: README gets a 2-3 sentence pitch; the full
   narrative lives only in the vignette.
3. **Data dictionary** — the full 20-column table lives in README **and** a
   parallel (slightly shorter) `@format` list lives in `?rwb_standardized`
   **and** the vignette repeats a "key columns" bullet subset. Convention:
   the `@format`/`@details` roxygen block is the single canonical dictionary
   (it's what CRAN/pkgdown treat as authoritative); README/vignette should
   summarize a handful of columns at most and link to `?rwb_standardized`.
4. **Data quality notes** (2011 missing, score comparability, dimensions
   only from 2022+, ISO coverage) — stated three times: README "Data Notes",
   vignette FAQ, and `@details` in `R/data.R`. The FAQ framing (narrative
   Q&A, including the scaling-bug story) is genuinely different in kind from
   a dictionary entry, so it's fine for the vignette to keep this — but
   README's version should shrink to one or two lines pointing at the FAQ
   rather than re-stating all five bullets.
5. **Citation block** — the same BibTeX is pasted into both README and the
   vignette FAQ, with no `inst/CITATION` file. R's actual mechanism for this
   is `inst/CITATION`, read via `citation("pressfreedom.data")`; both docs
   should point to that single source instead of embedding copies.

## Proposed edits

### 1. Create `inst/CITATION`
Canonical citation source (`bibentry()`-based), covering both the package
and (as a `note`) a reference to citing RSF's original index separately.
README and the vignette both replace their BibTeX blocks with a one-line
pointer: `citation("pressfreedom.data")`.

### 2. Trim `README.md`
- **Overview**: cut to a 2-3 sentence pitch (what it is, what problem it
  solves). Move the detailed 4-phase pipeline description entirely into the
  vignette's "Why This Package?" (it's already there in similar form).
- **Installation**: keep as-is *and* become the sole owner — add the
  GitHub/pak/remotes options currently only in the vignette (README
  currently only shows `devtools::install()`, which only works from a local
  clone, not for actual users).
- **Quick Start**: keep the current minimal example (load + inspect +
  filter one country) as the README's teaser. Add one sentence at the end:
  "See `vignette("getting-started", package = "pressfreedom.data")` for a
  full walkthrough and FAQ."
- **Data Structure**: replace the full 20-row table with a short 4-5 row
  "key columns at a glance" plus `See ?rwb_standardized for the complete data
  dictionary.` (mirrors what the vignette already does in its Quick Start).
- **Data Notes**: shrink to 2-3 lines (year 2011 gap, score comparability
  boundary) with `See the FAQ in vignette("getting-started") for details.`
  Drop the consolidation/territorial/ISO bullets (they're in `@details` and
  the vignette already).
- **Citation**: replace embedded BibTeX with pointer to
  `citation("pressfreedom.data")` (see #1).
- Keep unchanged: Annual Updates, Functions, Data Source, Development,
  License, Author, Related Projects (these aren't duplicated elsewhere).

### 3. Trim `vignettes/getting-started.Rmd`
- **Installation**: remove entirely (or collapse to one sentence: "If you
  haven't installed the package yet, see the README's Installation
  section," with a link) — README becomes sole owner.
- **Why This Package?**: keep as the canonical home for the pipeline/period/
  consolidation narrative (no change needed here; README will stop
  duplicating it after step 2).
- **Quick Start**: keep the `glimpse()` walkthrough and data-availability
  check; drop the "Key columns" bullet list (duplicates `@format`) and
  replace with `See ?rwb_standardized for the full column reference.`
- **FAQ**: keep as-is (this is unique, narrative content not found
  elsewhere) except the citation Q&A, which switches to pointing at
  `citation("pressfreedom.data")` instead of embedding BibTeX directly.

### 4. Cross-check after edits
- Confirm `R/data.R`'s `@format`/`@details` block is not missing anything
  now removed from README/vignette (e.g., double-check the Cyprus/
  territorial-variant explanation still exists somewhere canonical — it's
  already in `@details`, so no action needed, just verifying).
- Re-render both README (`devtools::build_readme()` if it's Rmd-generated —
  confirm whether `README.md` is hand-written or has a `README.Rmd` source)
  and the vignette (`devtools::build_vignettes()`) to make sure links/code
  chunks still work after trimming.
- Update `NEWS.md` with a short "Documentation" entry noting the README/
  vignette de-duplication (per this project's existing pattern of logging
  doc changes).

## Notes carried into the upcoming pkgdown plan

This cleanup should happen *before* the pkgdown site is built
(`2026-08-01-pkgdown-website.md`), since pkgdown will render README as the
homepage and `getting-started.Rmd` as a nav tab side-by-side — the
duplication would be immediately visible to site visitors clicking between
the two.

## Open questions for you

1. Is `README.md` hand-maintained, or generated from a `README.Rmd`? (Found
   only `README.md` on disk — confirming there's no `README.Rmd` source I
   should edit instead.)
2. For the trimmed README "Data Structure" section, do you want to keep a
   small table (e.g., `year_n`, `iso`, `country_en`, `score`, `rank`) or drop
   the table entirely in favor of prose + link to `?rwb_standardized`?
3. Should `inst/CITATION` also include a separate `bibentry` for citing RSF's
   Press Freedom Index itself (as the vignette FAQ currently does with a
   second `@organization` block), or should that stay as vignette-only prose
   since RSF citation format isn't really "this package's" citation?
