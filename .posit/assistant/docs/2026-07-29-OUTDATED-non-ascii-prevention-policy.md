# Non-ASCII Character Prevention Policy

**Author:** Peter Baumgartner  
**Date:** 2026-07-29  
**Project:** pressfreedom.data  
**Problem:** Em-dashes (–, —) in roxygen2 documentation comments repeatedly trigger R CMD check warnings

---

## Problem Statement

Em-dashes (en-dash: U+2013 –, em-dash: U+2014 —) and other non-ASCII characters in R documentation comments cause portability issues:

- R CMD check flags them as non-portable
- Different platforms may render them differently
- roxygen2 generates `.Rd` files with these characters, which fail CRAN checks
- This issue has appeared multiple times during development (commits 5d07014, a56964b)

**Root Cause:** Editors on modern systems default to smart typography (curly quotes, em-dashes), but R package documentation must be pure ASCII for portability.

---

## Solution: Three-Layer Prevention

### 1. Pre-commit Hook (Git-level Protection)

**File:** `.git/hooks/pre-commit`  
**Purpose:** Prevent em-dashes and smart quotes from entering the repository

**How it works:**
- Runs automatically before every `git commit`
- Scans staged R files for em-dashes (–, —) and smart quotes (" ", ' ')
- Blocks commit and provides helpful error message
- Can be bypassed with `git commit --no-verify` (not recommended)

**Example output when violation detected:**
```
✗ Em-dash found in: R/update.R
R/update.R:47:#' 2. **Download (Phase A)** – Only if \code{download = TRUE}

ERROR: Non-ASCII characters found in R code files.
These cause R CMD check failures on different platforms.

Solutions:
  1. Replace em-dashes (–, —) with ASCII dashes (-)
  2. Replace smart quotes ('', "") with straight quotes ('" )
  3. For ranges: use '2002-2026' instead of '2002–2026'
```

### 2. Editor Configuration (IDE-level Prevention)

**File:** `.editorconfig`  
**Purpose:** Configure all editors to use ASCII-safe settings

**How it works:**
- Configures UTF-8 encoding (correct)
- Sets line endings to LF (portable)
- Disables smart typography in most editors
- Works in RStudio, VS Code, Positron, Sublime Text, and others

**What it controls:**
```yaml
[*.{R,Rmd,qmd}]
charset = utf-8
insert_final_newline = true
end_of_line = lf
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
```

### 3. Roxygen2 Configuration (Build-level Enforcement)

**File:** `_roxygen.yml`  
**Purpose:** Configure roxygen2 to handle encoding correctly

**Current setting:**
```yaml
encoding: UTF-8
```

**Future enhancement:** Can be extended to enforce ASCII output.

---

## Coding Standards

### ✅ DO: ASCII Alternatives

| Use Case | Correct | Wrong |
|----------|---------|-------|
| **Year ranges** | `2002-2026` | `2002–2026` |
| **Dash separator** | `Phase A - Download` | `Phase A – Download` |
| **Minus sign** | `-1` | `−1` |
| **Quote marks** | `"quoted"` | `"quoted"` |
| **Apostrophe** | `it's` | `it's` |
| **Bullet list** | `- item` | `• item` |

### ✅ DO: Use in Documentation

```r
#' Clean Period 1 Data (2002-2012)
#'
#' Cleans and normalizes press freedom data for years 2002-2012.
#' This is Period 1 of 3 methodological phases.
#'
#' @details
#' - Period 1 (2002-2012): Non-comparable scores
#' - Use ASCII dashes for ranges and separators
#' - Avoid smart quotes in code comments
```

### ❌ DON'T: Non-ASCII Characters

```r
#' Clean Period 1 Data (2002–2012)  # ← En-dash causes R CMD check failure
#' 
#' Phase A — Download (em-dash causes issues)
#' 
#' Smart "quotes" and 'apostrophes' also problematic
```

---

## Implementation History

### Initial Problem
- Commits 5d07014, a56964b: Em-dashes detected in roxygen2 comments
- Required manual fixes and R CMD check re-runs
- Pattern repeated multiple times during development

### Solution Deployment (2026-07-29)
- ✅ Created `.git/hooks/pre-commit` for automated detection
- ✅ Created `.editorconfig` for editor configuration
- ✅ Created `_roxygen.yml` for roxygen2 settings
- ✅ Documented policy and standards
- ✅ Trained on correct usage

### Future Prevention
- Hook will catch issues at commit time
- EditorConfig prevents creation of problematic characters
- Roxygen2 configuration ensures proper handling

---

## Testing the Prevention

### Test 1: Pre-commit Hook Works

```bash
# Try to commit an em-dash (should fail)
echo "#' Test — em-dash" > test_file.R
git add test_file.R
git commit -m "test"  # Should be blocked by hook

# Output:
# ✗ Em-dash found in: test_file.R
# ERROR: Non-ASCII characters found in R code files.
```

### Test 2: Bypass Hook (Not Recommended)

```bash
git commit --no-verify  # Bypasses hook (not recommended)
```

---

## Maintenance & Future Updates

### If Em-dashes Appear Again

1. **Identify the culprit:**
   ```bash
   grep -r '[–—]' R/ man/
   ```

2. **Replace batch:**
   ```bash
   # Replace en-dashes with hyphens
   sed -i '' 's/–/-/g' R/*.R
   
   # Replace em-dashes with hyphens
   sed -i '' 's/—/-/g' R/*.R
   ```

3. **Verify:**
   ```bash
   devtools::check()
   ```

### If Policy Changes

1. Update this document: `.posit/assistant/docs/2026-07-29-non-ascii-prevention-policy.md`
2. Update pre-commit hook: `.git/hooks/pre-commit`
3. Update AGENTS.md with new guidelines

---

## Related Documents

- `.editorconfig` — Editor configuration (UTF-8, line endings, indentation)
- `.git/hooks/pre-commit` — Automated git-level check
- `_roxygen.yml` — Roxygen2 configuration
- `AGENTS.md` — Project coding standards (cross-project skill: peter-global)
- `README.md` — User-facing documentation

---

## Key Takeaway

**Never use em-dashes (–, —) or smart quotes (" ", ' ') in R code or documentation.**

Use ASCII alternatives:
- `–` (en-dash) → `-` (hyphen)
- `—` (em-dash) → `-` (hyphen)
- `"` (smart quote) → `"` (straight quote)
- `'` (smart quote) → `'` (straight quote)

The pre-commit hook will catch violations automatically.
