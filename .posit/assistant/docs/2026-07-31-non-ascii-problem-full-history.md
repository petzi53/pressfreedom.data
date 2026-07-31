# The Non-ASCII Problem: Full History and Final Resolution

**Date:** 2026-07-31
**Status:** Resolved (source-code enforcement + data-content mojibake both addressed)

## Why this note exists

The non-ASCII issue came up repeatedly across multiple sessions (2026-07-29,
2026-07-30, 2026-07-31), each time looking like a new problem. It wasn't one
problem -- it was **two distinct problems** that kept getting entangled:

1. **Source-code ASCII enforcement** -- keeping `*.R`, `*.Rmd`, `*.Rd`,
   `DESCRIPTION`, `NAMESPACE` free of non-ASCII characters, as required by
   `R CMD check --as-cran` and CRAN.
2. **Data-content encoding corruption (mojibake)** -- the actual *data
   values* (country names, zone names) arriving from RSF's source files with
   corrupted character encoding, independent of anything in the R source.

Fixing #1 never touched #2, and every time #2 resurfaced it looked like a
regression of #1. This note lays out the full timeline so future sessions
don't re-diagnose the same ground.

---

## Part 1: Source-code ASCII enforcement (2026-07-29 to 2026-07-30)

### v1: the broken hook (2026-07-29)

- **Doc:** `2026-07-29-OUTDATED-non-ascii-prevention-policy.md`
- A pre-commit hook was added using a bash character class
  (`["'']`-style patterns) intended to catch curly quotes, em-dashes, etc.
- **What was wrong:** the character class had silently degraded into
  matching plain ASCII quotes, so it flagged almost every normal R string
  literal. This trained the habit of `git commit --no-verify`, which meant
  *real* violations could slip through unnoticed. The hook also only lived
  in `.git/hooks/` (never version-controlled), so a fresh clone had zero
  protection.
- As a workaround at the time, accented characters that legitimately
  needed to appear in R source (e.g., diacritic-removal regex patterns in
  `standardize.R`) were written as explicit Unicode escapes
  (`"\u0043\u00f4\u0074\u0065"` for "Côte") specifically to dodge the
  broken hook. This escape-heavy style is itself a symptom of problem #1
  colliding with problem #2 -- more on this below.

### v2: the robust hook (2026-07-30)

- **Doc:** `2026-07-30-non-ascii-prevention-v2.md` (current reference)
- Replaced the fragile bash character class with
  `.githooks/check_ascii.py`: a pure-Python scanner that flags *any*
  character with `ord(ch) > 127` -- a numeric comparison, not an
  enumerated "bad character" list that can silently degrade.
- Reports line/column, Unicode name, and a suggested ASCII replacement.
- Checks staged content via `git show :path` so partially-staged files are
  validated correctly.
- `.githooks/pre-commit` is a thin, version-controlled wrapper
  (`exec python3 ... --staged`), enabled per-clone via
  `git config core.hooksPath .githooks`.
- **Scope, deliberately narrow:** only `*.R`, `*.Rmd`, `*.Rnw`, `*.Rd`,
  `.qmd`, `DESCRIPTION`, `NAMESPACE` -- i.e., only what actually matters
  for `R CMD check`/CRAN. Explicitly **excludes** `inst/extdata/` (raw RSF
  data, legitimately non-ASCII), `data-raw/`, `data/`, `renv.lock`, and
  `.posit/`.
- Verified with a false-positive regression test (plain ASCII quotes
  pass), a true-positive test (en-dash/em-dash/curly quotes/accents/arrows
  all caught with diagnostics), an end-to-end `git commit` block test, and
  a full-codebase scan that surfaced and fixed real pre-existing
  violations in `R/clean.R`, `R/data.R`, and stale generated `.Rd` files
  that v1's narrow character list had missed entirely.
- Also produced two follow-on docs: `2026-07-30-non-ascii-prevention-retrofit-guide.md`
  and `2026-07-30-non-ascii-prevention-starter-template.md`, for retrofitting
  the same pattern onto other projects.

**Key point:** v2 is scoped to *source code*, by design. It was never meant
to catch corruption inside the shipped data objects (`data/*.rds`,
`data/*.rda`), because those are binary R serialization formats, not text
files a `git diff` or grep-based scanner can reasonably inspect.

---

## Part 2: Data-content mojibake (2026-07-31, this session)

### How it surfaced

While reviewing the `getting-started.Rmd` vignette plan (Q4 in
`2026-07-30-2339-plan.md`), running `dplyr::glimpse(rwb_standardized)`
exposed a corrupted value in the `zone` column: `"AmÃ©riques"` sitting
alongside a correctly-formed `"Ameriques"` -- i.e., the Americas zone had
been silently split into two distinct values.

This is **not** a v2-hook gap. `zone`'s corrupted text lives inside
`data/processed/rwb_standardized.rds` and `data/rwb_standardized.rda` --
binary data files the hook explicitly and correctly excludes. This is a
genuine data-cleaning bug in `R/standardize.R`, unrelated to the
source-code-ASCII policy.

### Root cause

`R/standardize.R`'s `consolidate_and_standardize_countries()`, Step 3, had
previously "fixed" this by hand-enumerating specific mojibake byte
sequences as `stringr::str_replace_all()` patterns -- one pattern per known
corrupted variant, written as explicit Unicode escapes (again, to satisfy
the ASCII-only source-code policy). Two `zone` patterns were coded:

1. A **double-encoded** mojibake variant (`Ã` + `ƒ` + `Â` + `©` sequence).
2. The **already-correct**, properly accented UTF-8 form (`é`, U+00E9).

The actual corrupted value in the data, `"AmÃ©riques"`, was a **third,
single-pass** mojibake variant (UTF-8 bytes of `é`, i.e. `0xC3 0xA9`,
decoded once as Latin-1) that neither hand-written pattern matched. So the
fix worked for the 2022+ period's data but silently missed 2002-2021,
leaving the duplicate `zone` value in the shipped dataset. This is exactly
the whack-a-mole failure mode the user flagged as recurring: fixing one
observed corrupted string doesn't fix the *class* of bug, so the next
differently-corrupted string sails through untouched.

### The fix: a general repair function, not another regex

Rather than adding a fourth hand-written pattern (whack-a-mole again),
`R/standardize.R` gained a new, general-purpose helper:

```r
repair_and_asciify <- function(x, max_passes = 3) {
  # A "\u00c3" or "\u00c2" character immediately followed by a Latin-1
  # continuation-range character is the telltale sign of UTF-8 bytes that
  # were decoded as Latin-1
  looks_mojibake <- function(s) {
    !is.na(s) & grepl("[\u00c2\u00c3][\u0080-\u00bf]", s, perl = TRUE)
  }

  for (i in seq_len(max_passes)) {
    suspicious <- looks_mojibake(x)
    if (!any(suspicious)) break

    repaired <- x
    # Re-encode the (wrongly decoded) characters back to their original
    # bytes, then reinterpret those bytes as UTF-8
    latin1_bytes <- iconv(x[suspicious], from = "UTF-8", to = "latin1", sub = "byte")
    Encoding(latin1_bytes) <- "UTF-8"
    is_valid <- !is.na(latin1_bytes) & validUTF8(latin1_bytes)
    repaired[suspicious][is_valid] <- latin1_bytes[is_valid]

    if (identical(repaired, x)) break
    x <- repaired
  }

  stringi::stri_trans_general(x, "Latin-ASCII")
}
```

How it differs from the previous approach:

- **Detection is generic**, based on the byte-level signature of
  Latin-1-decoded UTF-8 (`Ã`/`Â` followed by a continuation-range
  character), not a list of specific known-bad strings.
- **Repair is generic**: reinterpreting bytes rather than matching known
  broken words. It handles any corrupted word (country or zone name),
  present or future, without a code change.
- **Handles arbitrary corruption depth** by iterating (up to 3 passes),
  so both the single-pass and double-pass mojibake variants are resolved
  by the same code path.
- **Finishes with `stringi::stri_trans_general(x, "Latin-ASCII")`**, a
  general transliteration call, replacing the need for *any*
  hand-maintained list of accented-name-to-ASCII substitutions (Cote,
  Turkiye, Curacao, Sao Tome, Principe, Reunion, etc.). This is also what
  eliminated the Unicode-escape-laden source code from Part 1 -- the
  function body is now plain ASCII by construction, not because of manual
  escaping.

Applied uniformly to both `country_en` and `zone` in Step 3.

### Verification performed before committing

1. Prototyped the function standalone against 9 test strings covering the
   single-pass mojibake, double-pass mojibake, already-correct ASCII,
   and five properly-accented country names (Côte d'Ivoire, Türkiye,
   Curaçao, São Tomé, Príncipe, Réunion) -- all produced correct ASCII
   output.
2. Re-ran `standardize_rwb_countries()` to regenerate
   `data/processed/rwb_standardized.rds`.
3. Re-ran `data-raw/rwb_standardized.R` to regenerate
   `data/rwb_standardized.rda` (the object users actually load).
4. Confirmed `zone` now has exactly 6 distinct values (was 7).
5. Diffed `country_en` before/after: **identical set**, confirming the fix
   only removed the zone duplicate and didn't introduce any unintended
   country merges or splits.
6. Re-rendered `vignettes/getting-started.Rmd` end-to-end against the
   regenerated data -- clean.
7. Ran `.githooks/check_ascii.py` against every touched file. It initially
   caught **literal mojibake characters that had been pasted into code
   comments** while documenting the fix (an accidental instance of problem
   #2 leaking into problem #1's territory) -- these were rewritten as
   plain-English descriptions before committing.

### Commits

- `66ba0ff` -- **fix:** repair zone mojibake generically instead of
  per-string regex. Adds `repair_and_asciify()`, applies it to
  `country_en` and `zone`, adds `stringi` to `Imports`, regenerates
  `rwb_standardized.rds`/`.rda`, adds `man/repair_and_asciify.Rd`.
- `a6b291f` -- **docs (separate commit):** adds the `NAMESPACE` export and
  `.Rd` file for `resolve_percent_scaling()`, a gap left over from the
  unrelated 100x-scaling-bug commit (`f5588f0`) where `devtools::document()`
  hadn't been re-run. Kept separate from the mojibake fix since it's an
  unrelated cleanup that happened to surface during the same
  `devtools::document()` call.

---

## Lessons for future sessions

1. **Two different problems share the name "non-ASCII"** -- keep them
   mentally (and procedurally) separate:
   - Source-code hygiene (CRAN/R-CMD-check compliance) -> `.githooks/check_ascii.py`,
     scoped to text source files.
   - Data-content encoding correctness -> a data-quality concern, checked
     by inspecting the actual data (`dplyr::distinct()`, `glimpse()`), not
     by the pre-commit hook.
2. **Hand-enumerated regex lists for encoding fixes are a trap.** Every
   fix of this shape (v1's character class, the original per-string zone
   patterns) eventually missed a variant because the list was reactive
   (built from observed bad strings) rather than generic (built from the
   byte-level *mechanism* that produces bad strings). Prefer detecting the
   corruption pattern generically and repairing it algorithmically.
3. **`stringi::stri_trans_general(x, "Latin-ASCII")` is the right tool for
   ASCII transliteration** of legitimately accented text -- it removed the
   need for the hardcoded Cote/Turkiye/Curacao/etc. substitution list
   entirely, and as a side effect eliminated the Unicode-escape-heavy
   source code that existed only to dodge the ASCII pre-commit hook.
4. **When writing code comments *about* mojibake or encoding bugs, don't
   paste the corrupted characters into the comment.** They'll trip the
   same ASCII hook meant to catch unrelated issues. Describe them in
   words or use `\uXXXX` escapes instead.
5. **Binary data files (`.rds`/`.rda`) are outside the hook's reach by
   design** -- and should stay that way; verify data-content correctness
   with data-inspection code, not by trying to widen the pre-commit
   hook's scope to binary files.

## Related documentation

- `2026-07-29-OUTDATED-non-ascii-prevention-policy.md` -- v1 policy (superseded)
- `2026-07-30-non-ascii-prevention-v2.md` -- current source-code hook reference
- `2026-07-30-non-ascii-prevention-retrofit-guide.md` -- retrofitting the hook to other projects
- `2026-07-30-non-ascii-prevention-starter-template.md` -- starter template
- `2026-07-30-2339-plan.md` -- vignette plan where the zone mojibake bug (Q4) was first surfaced
