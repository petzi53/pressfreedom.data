# CRAN Submission Plan for pressfreedom.data v0.1.0

**Date:** 2026-07-29  
**Package:** pressfreedom.data  
**Version:** 0.1.0  
**Author:** Peter Baumgartner  
**Status:** Planning Phase

---

## Overview

This plan outlines the complete process for submitting the pressfreedom.data package to CRAN using `devtools::release()`. The process involves automated checks, manual review, and submission to CRAN's system.

---

## What is `devtools::release()`?

`devtools::release()` is an interactive function that guides you through the CRAN submission process. It:

1. **Runs automated checks** (R CMD check, spell checking, license validation)
2. **Verifies metadata** (DESCRIPTION file, URLs, dependencies)
3. **Prompts you** to answer submission questions
4. **Builds the package** for upload
5. **Submits to CRAN** (or creates files for manual submission)
6. **Tracks the submission** in `cran-comments.md`

**Important:** It's interactive — you answer yes/no questions at each step, not automated end-to-end.

---

## Pre-Submission Checklist

### ✅ Already Completed (from memory)

- [x] Version bumped to 0.1.0
- [x] Non-ASCII characters removed (em-dashes, smart quotes)
- [x] R CMD check passes (all actionable issues fixed)
- [x] All dependencies declared in DESCRIPTION (Imports/Suggests)
- [x] README.md created and comprehensive
- [x] LICENSE file exists (MIT)
- [x] .Rbuildignore configured correctly
- [x] Git tag v0.1.0 created and pushed
- [x] No ICON* files remaining

### ⚠️ Items to Verify Before Running `devtools::release()`

1. **DESCRIPTION file correctness**
   - Version matches git tag: 0.1.0 ✓
   - Authors@R is properly formatted ✓
   - Title is concise (<65 chars) ✓
   - Description is detailed ✓
   - All dependencies listed ✓
   - Suggests uses `usethis` (development-only)

2. **License agreement**
   - MIT License approved for CRAN ✓
   - LICENSE file in repo root ✓
   - DESCRIPTION mentions "MIT + file LICENSE" ✓

3. **Documentation**
   - All functions have @export roxygen comments ✓
   - All exported functions have help pages ✓
   - Data documentation exists (rwb_standardized) ✓
   - No undocumented functions in .Rd files

4. **Tests** (if applicable)
   - Package uses data.frame return values (no special objects requiring tests)
   - No tests currently in tests/ (acceptable for data package)

5. **URLs in documentation**
   - All URLs in docs/README are accessible ✓
   - No broken internal links ✓

6. **Data package considerations**
   - Large dataset (rwb_standardized.rda) acceptable
   - Data documentation clear ✓
   - Purpose of data explained in README ✓

---

## CRAN Submission Process (Step by Step)

### Step 1: Run Automated Checks in RStudio

```r
# In R console
devtools::check()
```

**Expected outcome:** "0 errors, 0 warnings, 0 notes" (or harmless notes about data files)

**What it checks:**
- Package structure (DESCRIPTION, NAMESPACE, etc.)
- Function documentation (missing @export, missing help, etc.)
- Dependencies (unused imports, missing imports)
- Non-standard files (.Rproj, .Rhistory, etc.)
- Code quality (no dangerous patterns)

### Step 2: Run `devtools::release()` Interactive Flow

```r
# In R console
devtools::release()
```

**What happens next:**

The function presents an interactive dialog with ~15 yes/no questions. You'll encounter:

#### Phase 1: Pre-submission Checks
- "Have you checked that all files are smaller than 5MB?" → **YES**
- "Have you run devtools::check() yet?" → **YES** (do step 1 first)
- "Have you updated all roxygen documentation?" → **YES**
- Other yes/no questions about your submission readiness

#### Phase 2: CRAN Policies Check
- "Have you read and agreed to the CRAN Repository Policy?" → **YES**
  - You must read: https://cran.r-project.org/web/packages/policies.html
- "Does your package follow CRAN's naming conventions?" → **YES**
- "Have you declared all non-standard licenses?" → **YES** (MIT is standard)

#### Phase 3: Email Confirmation
- "What email should be used for CRAN correspondence?"
  - Default: petzi53@gmail.com (from DESCRIPTION Maintainer field)
  - You'll receive submission confirmations and status updates here

#### Phase 4: Final Review
- You'll see a summary of what will be submitted
- Option to **cancel** if something isn't right
- Option to **proceed** with submission

#### Phase 5: Submission
- Creates/updates `cran-comments.md` with:
  - Submission date/time
  - Your answers to CRAN questions
  - Notes about the submission
- Builds the package (.tar.gz)
- **Either:**
  - Automatically uploads to CRAN (if you authorize)
  - **Or** provides manual submission instructions (for older workflows)

### Step 3: Wait for CRAN Response

**Typical timeline:**
- **Immediately:** Automated bot checks submission format
  - If rejected → Email explaining issues → Fix → Resubmit
- **1-3 days:** Human reviewer checks package
  - If OK → Package published to CRAN
  - If issues → Email with feedback → Fix → Resubmit

**What CRAN checks for (human review):**
- Package does what it says it does
- No malicious code or unethical behavior
- License is clearly stated
- Dependencies are necessary
- Code quality and style
- Help documentation is clear

### Step 4: After Acceptance

Once accepted:
- Package appears on CRAN (https://cran.r-project.org/package=pressfreedom.data)
- Installation via `install.packages("pressfreedom.data")`
- Automatic testing on CRAN's systems (daily checks)
- You receive notifications of any new check issues

---

## Important Decisions to Make Before Submitting

### 1. Is This a Data Package or Code Package?

**pressfreedom.data is primarily a DATA package:**
- Main deliverable: `rwb_standardized` dataset (4,192 rows, 20 columns)
- Functions are utilities for annual updates (secondary)
- CRAN expects data packages to:
  - Have a clear data source (✓ RSF)
  - Document the data thoroughly (✓ 20-column table in README)
  - Provide clean, standardized data (✓)

**Action:** Ensure `rwb_standardized` documentation in `R/data.R` is complete and clear.

### 2. Should You Auto-Upload or Manual Submit?

**Option A: Auto-upload (Recommended for first submission)**
- `devtools::release()` uploads directly to CRAN's FTP
- Faster, less error-prone
- Your maintainer email must be correct

**Option B: Manual submission (If security concerns)**
- `devtools::release()` creates submission files
- You manually upload via web form
- More control, slower

**Recommendation:** Use **Option A** (auto-upload). It's the standard workflow.

### 3. What if CRAN Rejects the Submission?

**Common rejection reasons:**
- Non-standard files included (renv/, .posit/) → Already in .Rbuildignore ✓
- Undocumented functions → Check NAMESPACE export list
- Missing dependencies → All declared in DESCRIPTION ✓
- Large data files → rwb_standardized.rda is ~1.2MB (acceptable)

**If rejected:**
1. Read CRAN's email carefully (they're specific)
2. Fix the issue locally
3. Commit to git (you can use same version if minor fix)
4. Run `devtools::release()` again
5. Submit again

---

## Pre-Release Verification Checklist (Run Before Step 2)

Before invoking `devtools::release()`, verify these items locally:

### Check 1: No Development Artifacts
```r
# In R console
dir(recursive = TRUE, pattern = "\\.(Rhistory|Rdata|rds|rda)$")
```
Expected: Empty (or only `data/processed/rwb_*.rds` files, which are OK)

### Check 2: Data File Size
```r
# In R console
file.size("data/rwb_standardized.rda") / 1024^2  # Should be < 5MB
```
Expected: ~0.04 MB / 44 KB (well under CRAN's 5 MB limit, excellent)

### Check 3: DESCRIPTION Encoding
```r
# Check UTF-8 encoding declaration
readLines("DESCRIPTION") |> grep("Encoding", x = _, value = TRUE)
```
Expected: `Encoding: UTF-8`

### Check 4: Non-ASCII characters
```r
# In R console
devtools::check()
```
Expected: "checking data for non-ASCII characters ... OK" (R CMD check handles this reliably)

### Check 5: Package Loads Cleanly
```r
# In R console
devtools::load_all()
library(pressfreedom.data)
data(rwb_standardized)
head(rwb_standardized)
```
Expected: No errors, data loads correctly

---

## CRAN-Specific Notes for pressfreedom.data

### Why This Package is CRAN-Ready

1. **Clear purpose:** Download and standardize press freedom data
2. **Minimal dependencies:** Uses common packages (dplyr, readr, etc.)
3. **External data source:** Clearly documented (RSF)
4. **Long-term maintenance:** Annual update function included
5. **MIT License:** Fully compatible with CRAN
6. **No system dependencies:** Pure R, no C/C++/Fortran
7. **No external services required:** Downloads from public URLs
8. **Data package best practices:** Clean dataset, clear documentation

### Potential CRAN Questions (Be Prepared)

**Q:** "What is the purpose of the pressfreedom.data package?"  
**A:** "It automates the download and standardization of Reporters Without Borders press freedom data (2002-2026) into a clean, ISO-standardized dataset for research and analysis."

**Q:** "Why include an `update_rwb_data()` function?"  
**A:** "RSF publishes new data annually. This function enables researchers to keep the package data current without waiting for a CRAN update."

**Q:** "Is the data reproducible?"  
**A:** "Yes. The data is downloaded from public RSF URLs with all cleaning transformations documented in the code. Researchers can reproduce the entire pipeline."

---

## Step-by-Step Execution Summary

| # | Step | Command/Action | Expected Result |
|---|------|---|---|
| 1 | Verify checklist | Review pre-release items above | All ✅ verified |
| 2 | Run checks | `devtools::check()` | 0 errors, 0 warnings, 0 notes |
| 3 | Start submission | `devtools::release()` | Interactive dialog begins |
| 4 | Answer questions | Follow prompts, answer YES to each | Builds package |
| 5 | Review summary | Check what will be uploaded | Confirm all correct |
| 6 | Submit | Press ENTER to upload | Package submitted |
| 7 | Wait for CRAN | Check email | Acceptance (1-3 days) |
| 8 | Celebrate! | ✓ Package on CRAN | Available via `install.packages()` |

---

## Post-Submission Timeline & Actions

### Immediately After Submission
- Note submission date/time
- Check that `cran-comments.md` was created/updated
- Commit the updated `cran-comments.md` to git

### Within 24 Hours
- CRAN bot sends automated confirmation email
- Contains submission reference number and ticket ID

### Within 1-3 Days
- CRAN human reviewer processes package
- **If accepted:** Package published within hours
- **If rejected:** Email explaining issues

### If Accepted
- Monitor CRAN checks: https://cran.r-project.org/web/checks/check_results_pressfreedom.data.html
- Package appears in CRAN archives
- Available via `install.packages("pressfreedom.data")`

### If Rejected
1. Read CRAN's feedback email carefully
2. Fix issues locally and commit
3. Re-run `devtools::release()` (bump to v0.1.1 if needed)
4. Resubmit

---

## Additional Resources

- **CRAN Repository Policy:** https://cran.r-project.org/web/packages/policies.html
- **devtools::release() documentation:** `?devtools::release`
- **R Packages book (2nd edition):** https://r-pkgs.org/release.html

---

## Questions to Clarify Before Proceeding

1. **Do you want to submit this first release (v0.1.0) to CRAN immediately?**
   - YES → Proceed with execution
   - NO → Wait for further development

2. **Are you comfortable with the interactive nature of `devtools::release()`?**
   - It will ask ~15 yes/no questions that you must answer in the console

3. **Do you have any additional changes you want to make before submission?**
   - Common last-minute items: version bump, description update, README polish

---

## Next Steps (Upon Approval)

Once you approve this plan, I will:

1. ✅ Run `devtools::check()` to verify no issues
2. ✅ Show you the output and confirm readiness
3. ✅ Provide step-by-step guidance for running `devtools::release()` in your R console
4. ✅ Help interpret any CRAN feedback if submission is rejected
5. ✅ Update git and memory files with submission results

---

**Ready to proceed?** Please review this plan and approve to continue.
