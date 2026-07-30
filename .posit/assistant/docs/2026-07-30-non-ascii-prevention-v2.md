# Non-ASCII Prevention: Version 2 (Root Cause Fix)

**Author:** Peter Baumgartner (with Posit Assistant)
**Date:** 2026-07-30
**Supersedes:** `2026-07-29-non-ascii-prevention-policy.md`
**Problem:** The v1 pre-commit hook produced constant false positives, training the
habit of `git commit --no-verify` - which defeated the entire purpose of the check.

---

## Root Cause of the v1 Failure

The v1 hook detected "smart quotes" with:

```bash
if grep -q '[""'']' "$file"; then
```

Inspecting the actual bytes stored in `.git/hooks/pre-commit` showed the bracket
expression had degraded into:

```
["'']
```

That is, **plain ASCII double and single quotes** - not curly quotes at all. Every
normal R string literal (`"Germany"`, `country_en`, etc.) matched, so nearly every
commit touching an `.R`/`.Rmd` file was flagged as a "smart quotes" violation.

**Why this happened:** embedding literal multi-byte Unicode characters inside a
bash single-quoted string, inside a `.git/hooks/` file that is never version
controlled, is fragile. Any editor re-save, copy-paste through a terminal, or
encoding mismatch can silently mutate the bytes. Bash character classes give no
feedback when this happens - the script still runs, just against the wrong
pattern.

A second, independent problem: `.git/hooks/` is **not tracked by git**. The hook
only ever existed on one machine's local clone. A fresh clone (or another
contributor) would get no protection at all, silently.

---

## Design Principles for v2

1. **No hand-typed Unicode literals in shell patterns.** All detection logic
   moved to Python, using `ord(ch) > 127` - a numeric comparison, not a
   character-class literal. There is nothing here for an editor or shell to
   corrupt.
2. **Detect the general case, not an enumerated list.** Rather than trying to
   list every "bad" character (em-dash, en-dash, curly quotes, ellipsis, ...),
   flag *any* character outside ASCII. This catches things the v1 list missed
   entirely (e.g. arrows `->`, accented letters like `e`-with-grave), which
   real violations in `R/clean.R`, `R/data.R`, and stale `.Rd` files revealed
   during this fix.
3. **Diagnose, don't just refuse.** Every violation is reported with exact
   line/column, the Unicode code point and name, and - where a safe,
   unambiguous mapping exists - a suggested ASCII replacement (`n-dash -> -`,
   `right arrow -> ->`, `e-acute -> e`).
4. **Check staged content, not the working tree.** Uses `git show :path`
   rather than reading the file off disk, so partially staged files
   (`git add -p`) are validated correctly.
5. **Version the hook in the repo.** Lives in `.githooks/`, wired up via
   `git config core.hooksPath .githooks` (a per-clone `git config` setting,
   but the hook logic itself now travels with the repository and can be
   re-applied with one command after a fresh clone).
6. **Narrow, deliberate scope.** Only checks files where non-ASCII characters
   actually break `R CMD check` / CRAN: `*.R`, `*.Rmd`, `*.Rnw`, `*.Rd`,
   `*.qmd`, `DESCRIPTION`, `NAMESPACE`. Explicitly excludes:
   - `inst/extdata/` - raw RSF source CSVs (legitimately contain
     original-language accented text; these are external data, not authored
     documentation)
   - `data-raw/`, `data/`, `renv/`, `renv.lock` - generated/vendored, not
     hand-authored source
   - `.posit/` - internal planning notes and session logs; not shipped with
     the package, and heavy use of arrows/checkmarks/box-drawing characters
     genuinely improves readability there. Enforcing ASCII purity on
     internal notes was solving a problem CRAN never had.

---

## What's in `.githooks/`

| File | Purpose |
|------|---------|
| `check_ascii.py` | Core scanner. Pure Python, no shell string literals to corrupt. Supports `--staged` (git hook mode) and explicit file arguments (manual/CI use). |
| `pre-commit` | Thin wrapper: `exec python3 .githooks/check_ascii.py --staged`. Intentionally contains zero character-class patterns. |

### Wiring it up (once per clone)

```bash
git config core.hooksPath .githooks
```

This is a local git config setting (not itself version-controlled), but since
the hook content now lives in the repo, a one-line note in `README.md` /
`AGENTS.md` is enough to restore protection after a fresh clone - unlike v1,
where the hook could only be recovered by remembering it existed and
reconstructing it from documentation.

### Manual / ad hoc scan

```bash
python3 .githooks/check_ascii.py $(git ls-files 'R/*.R' 'man/*.Rd' 'vignettes/*.Rmd' 'tests/*.R') DESCRIPTION NAMESPACE
```

---

## Verification Performed (2026-07-30)

1. **False-positive regression test:** a file containing only normal ASCII
   quotes and apostrophes now passes (`exit 0`) - this is exactly the case
   that broke every previous commit.
2. **True-positive test:** a file with an en-dash, em-dash, curly quotes, an
   accented letter, and an arrow is correctly flagged, each with line/column,
   Unicode name, and a suggested fix.
3. **End-to-end hook test:** staging a file with real violations and running
   `git commit` is blocked by the hook (not bypassed), with the same
   diagnostic output.
4. **Full codebase scope check:** ran the scanner across all files the hook
   is scoped to (`R/*.R`, `man/*.Rd`, `vignettes/*.Rmd`, `tests/*.R`,
   `DESCRIPTION`, `NAMESPACE`). This surfaced real, previously undetected
   violations that the v1 hook's narrow character list had missed entirely:
   - `R/clean.R` - a right-arrow in a roxygen comment
   - `R/data.R` - three instances of e-with-grave in "Reporters Sans
     Frontieres" (spelled with ASCII "e" going forward)
   - `man/clean_period_1.Rd`, `man/rwb_standardized.Rd`,
     `man/update_rwb_data.Rd` - stale generated docs reflecting the same
     issues
   All fixed at the source (`R/*.R`) and regenerated via `devtools::document()`.
5. **Re-ran full scope check after fixes: clean (`exit 0`).**

---

## Complementary Layer: `.editorconfig`

This fix focuses on **hard enforcement** (the hook). If your package has `.editorconfig`, that provides a **soft preventative layer** (editor defaults):

| Tool | Purpose | Layer | When |
|------|---------|-------|------|
| `.editorconfig` | Set editor defaults (UTF-8, line endings, indentation) | Soft prevention | When saving a file |
| `.githooks/check_ascii.py` | Detect & block non-ASCII at commit | Hard enforcement | When running `git commit` |

**Relationship:** Complementary, not redundant.
- If you have `.editorconfig`: Great. Keep it. It helps prevent violations in the first place.
- If you don't have `.editorconfig`: The hook alone is sufficient (and the critical protection).
- Either way: The hook is the enforcement layer that matters for CRAN compliance.

If you want to add `.editorconfig` to an existing package, ensure it specifies `charset = utf-8` for R-related files:

```editorconfig
[*.{R,Rmd,qmd,Rd}]
charset = utf-8
# ... other settings
# Note: Actual non-ASCII prevention is enforced by .githooks/check_ascii.py
```

---

## Coding Standard (unchanged from v1)

Still applies: prefer ASCII alternatives for dashes, quotes, and arrows in
package source and documentation.

| Use case | Correct | Avoid |
|----------|---------|-------|
| Year ranges | `2002-2026` | `2002-2026` (en-dash) |
| Separator | `Phase A - Download` | `Phase A - Download` (em-dash) |
| Arrow/flow | `download -> clean -> combine` | `download -> clean` (unicode arrow) |
| Quotes | `"quoted"` | curly quotes |

The difference from v1 is not the standard - it's that the enforcement
mechanism now actually works, and only applies where it matters.

---

## If This Breaks Again

Because the check is now general (any code point > 127) rather than an
enumerated list, "new" problem characters can't sneak past it the way arrows
and accented letters did under v1. If a legitimate need for non-ASCII in a
checked file ever arises (e.g. a contributor's name in `DESCRIPTION`), handle
it explicitly:

- Use a documented Unicode escape (`\uXXXX`) in `.Rd`/roxygen comments where R
  supports it, or
- Add a narrowly-scoped exclusion to `EXCLUDED_FILES` / `EXCLUDED_PREFIXES` in
  `check_ascii.py` with a comment explaining why, rather than weakening the
  detection logic itself.
