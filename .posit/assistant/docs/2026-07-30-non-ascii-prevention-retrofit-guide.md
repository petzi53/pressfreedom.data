# Non-ASCII Prevention: Retrofit Guide for Existing R Packages

**Date:** 2026-07-30  
**Purpose:** Strategies for adding non-ASCII prevention to packages already in development or published.

---

## Overview

This guide covers three scenarios, each with a different risk profile and remediation strategy:

1. **Pre-release packages** (in active development, not on CRAN)
2. **Published packages** (on CRAN, stable)
3. **Abandoned/archived packages** (low maintenance)

---

## Scenario 1: Pre-Release Packages (In Development)

**Status:** Active development; no CRAN release yet.  
**Risk:** Violations not yet in git history; easy to prevent going forward.  
**Effort:** 30-60 minutes

### Quick Steps

1. **Set up the hook** (3 minutes)
   ```bash
   mkdir -p .githooks
   # Copy check_ascii.py and pre-commit from starter template
   chmod +x .githooks/pre-commit
   git add .githooks/
   git commit -m "chore: Add non-ASCII prevention hook"
   ```

2. **Enable locally** (1 minute)
   ```bash
   git config core.hooksPath .githooks
   ```

3. **Scan existing code** (5-10 minutes)
   ```bash
   python3 .githooks/check_ascii.py --all
   ```
   - If violations found: fix them, commit
   - If clean: move to step 4

4. **Update README.md** (5 minutes)
   - Add Development section with `git config core.hooksPath .githooks`
   - Add coding standards (ASCII only in R code)

5. **(Optional) Add CI check** (5 minutes)
   ```bash
   mkdir -p .github/workflows
   # Copy ci-ascii-check.yaml from starter template
   git add .github/workflows/ci-ascii-check.yaml
   git commit -m "ci: Add ASCII character check to CI"
   ```

6. **Document for contributors** (5 minutes)
   - Add to `CONTRIBUTING.md` or README Development section
   - Mention: `git config core.hooksPath .githooks` required after cloning

### Expected Outcome
- Hook active; prevents future violations
- Pre-release code stays clean
- Contributors know the setup requirement

---

## Scenario 2: Published Packages (CRAN or Otherwise)

**Status:** Released, stable version exists.  
**Risk:** Violations may already be in published code; fixing requires a new release.  
**Effort:** 1-3 hours (depending on violations found)

### Step 1: Decide on Scope

You have two options:

**Option A: Fix for Next Major Release**
- No immediate urgency; incorporate into next planned release cycle
- Good if: package is stable, few active changes
- Effort: Low (~30 min before release)

**Option B: Release Maintenance Patch**
- Act now; fix violations and release a patch (x.y.z+1)
- Good if: package is actively used, contributors are active
- Effort: Medium (~2 hours)

### Step 2: Scan Existing Code

```bash
python3 .githooks/check_ascii.py --all
```

Document violations found:
- Which files?
- How many violations?
- Type (accents, quotes, dashes)?

### Step 3: Create a Branch for Fixes

```bash
git checkout -b chore/non-ascii-prevention
```

### Step 4: Fix Violations

For each violation:

```r
# BEFORE (non-ASCII)
#' @description Reporters Sans Frontières dataset from 2002–2026

# AFTER (ASCII only)
#' @description Reporters Sans Frontieres dataset from 2002-2026
```

**Common fixes:**
| Violation | Fix | Example |
|-----------|-----|---------|
| Accented characters | Remove accent | `Côte d'Ivoire` → `Cote d'Ivoire` |
| Curly quotes | Use straight quotes | `"text"` → `"text"` |
| Em-dash in range | Use hyphen | `2002–2026` → `2002-2026` |
| Unicode arrow | Use ASCII arrow | `→` → `->` |

**Tools to help:**
- Regex find-replace in RStudio:
  - Find: `[""'']` (curly quotes) → Replace: `"` or `'`
  - Find: `[–—]` (dashes) → Replace: `-`
  - Find: `→` (arrow) → Replace: `->`

### Step 5: Regenerate Roxygen Docs

If you modified `.Rd` files directly (unlikely), skip. Otherwise:

```bash
devtools::document()
```

Commit any regenerated `man/` files.

### Step 6: Add Hook Infrastructure

```bash
mkdir -p .githooks
# Copy check_ascii.py and pre-commit from starter template
chmod +x .githooks/pre-commit
git add .githooks/
```

(Optional) Add CI check:
```bash
mkdir -p .github/workflows
# Copy ci-ascii-check.yaml from starter template
git add .github/workflows/ci-ascii-check.yaml
```

**Note:** If your package has `.editorconfig`, that's already providing a soft layer (editor defaults). The hook now adds hard enforcement at commit time. If you don't have `.editorconfig`, the hook alone is sufficient, but adding `.editorconfig` later is a good best practice.

### Step 7: Update Documentation

Add to `README.md` (Development section):
```markdown
## Development

After cloning, enable pre-commit hooks:

```bash
git config core.hooksPath .githooks
```

This prevents non-ASCII characters in R code (required for CRAN compliance).
```

### Step 8: Commit and Push

```bash
git commit -m "chore: Fix non-ASCII characters and add prevention hook"
# OR if multiple commits
git commit -m "chore: Fix non-ASCII characters"
git commit -m "chore: Add non-ASCII prevention hook"
```

### Step 9: Decide on Release

**If Option A (next major release):**
- Merge to `develop` branch
- Include in next planned release notes

**If Option B (maintenance patch):**
- Open PR; get review
- Merge to `main` (or `master`)
- Run release process:
  ```bash
  # Bump DESCRIPTION version: x.y.z -> x.y.(z+1)
  # Update NEWS.md
  devtools::build_readme()  # if applicable
  devtools::release()  # or manual CRAN submission
  ```

---

## Scenario 3: Abandoned or Archived Packages

**Status:** Package is archived, minimal maintenance, or personal reference.  
**Risk:** Low (not actively used); no release planned.  
**Effort:** 15-30 minutes (optional)

### Simple Option: Just Add the Hook

```bash
mkdir -p .githooks
# Copy check_ascii.py and pre-commit
chmod +x .githooks/pre-commit
git add .githooks/
git commit -m "chore: Add non-ASCII prevention hook"
```

**Benefit:** If the package is ever revived, it's protected going forward.  
**Downside:** Existing violations in history remain (not a problem for archived packages).

### Alternative: Full Cleanup (Only if Revisiting)

If you're revisiting the package for maintenance:
- Follow **Scenario 2** for full cleanup
- Consider a new minor release (x.(y+1).0)

---

## Quick Decision Matrix

| Package Status | Violations Found? | Action | Effort |
|---|---|---|---|
| **Pre-release** | Likely | Fix + add hook | 30–60 min |
| **Pre-release** | None | Just add hook | 15 min |
| **Published, active** | Yes | Fix + hook + patch release | 2–3 hrs |
| **Published, stable** | Yes | Fix + hook + next major release | 30 min (now) + release process |
| **Archived** | Yes | Optional; just add hook | 15 min |
| **Archived** | No | Optional; just add hook | 15 min |

---

## Finding All Your Existing Packages

### On Your Local Machine

```bash
# List all git repos with R packages
find ~/ -name "DESCRIPTION" -path "*/.git" | head -20

# For each package, check if it has the hook
for dir in $(find ~/ -name "DESCRIPTION" -path "*/.git" | xargs dirname | xargs dirname); do
  if [ -f "$dir/.githooks/check_ascii.py" ]; then
    echo "✓ $dir (protected)"
  else
    echo "✗ $dir (not protected)"
  fi
done
```

### On GitHub

If your packages are on GitHub:

```bash
# List all your repos (requires gh CLI)
gh repo list --json name,isArchived --limit 100

# For each repo, check if .githooks/ exists
for repo in $(gh repo list --json name --limit 100 | jq -r '.[].name'); do
  if gh repo view "$repo" --json "files" | grep -q ".githooks"; then
    echo "✓ $repo (protected)"
  else
    echo "✗ $repo (not protected)"
  fi
done
```

---

## Phased Rollout Strategy (Recommended)

If you have many packages, don't retrofit all at once. Use a phased approach:

### Phase 1: High-Priority Packages (Week 1)
- Actively maintained packages
- Packages with external contributors
- Packages recently submitted to CRAN

**Action:** Full remediation (Scenario 1 or 2, depending on status)

### Phase 2: Medium-Priority Packages (Week 2)
- Stable packages with occasional updates
- Personal reference packages

**Action:** Just add hook (15 min each)

### Phase 3: Low-Priority Packages (As Needed)
- Archived packages
- Packages rarely updated

**Action:** Optional; skip if not revisiting

---

## Testing Your Retrofit

After adding the hook, verify it works:

### Local Test

```bash
# Enable hook locally
git config core.hooksPath .githooks

# Create a test file with non-ASCII
cat > test_violation.R << 'EOF'
# This has a curly quote: "test"
EOF

git add test_violation.R
git commit -m "test: should fail"
# Should fail with diagnostic

# If it failed: ✓ Hook is working
# Remove the test file
git rm test_violation.R
git commit -m "test: remove violation"
```

### CI Test (If Using GitHub Actions)

```bash
# Push to a branch; CI will run
git push origin chore/non-ascii-prevention

# Check GitHub Actions tab for ci-ascii-check job
# Should pass (if all violations were fixed)
```

---

## Common Issues

### Issue: "Hook doesn't run after I cloned"

**Cause:** `git config core.hooksPath .githooks` not set.  
**Fix:** Document clearly in README.md + add to contributing guidelines.  
**Better:** Add to `.github/CONTRIBUTING.md`:

```markdown
## Development Setup

After cloning:

```bash
git config core.hooksPath .githooks
```

This enables the pre-commit hook that checks for non-ASCII characters.
```

### Issue: "Hook blocks my commit but I need to bypass it"

**Solution:** Not recommended, but possible:

```bash
git commit --no-verify
```

**Better:** Fix the violation first, then commit normally.

### Issue: "I already have `.git/hooks/pre-commit` from another tool"

**Solutions:**

1. **Use hook chaining** (recommended):
   ```bash
   # Edit .git/hooks/pre-commit to call both your tool and check_ascii.py
   existing_tool_hook
   python3 .githooks/check_ascii.py --staged
   ```

2. **Use a hook manager** (husky, pre-commit):
   - Configure your tool to run `.githooks/check_ascii.py --staged` as one step

3. **Disable hook manager** and use `.githooks/` (simplest):
   - Uninstall existing tool, use `.githooks/` only
   - Reconfigure `git config core.hooksPath .githooks`

### Issue: "The Python script doesn't work on Windows"

**Solution:** Python 3.8+ on Windows works fine. Ensure:
- `python3` is in PATH (not just `python`)
- Or use: `python .githooks/check_ascii.py --staged`

If neither works:
- Use Windows Subsystem for Linux (WSL)
- Or: Use CI-only check (no local pre-commit needed)

---

## Maintenance Going Forward

Once a hook is in place:

1. **All new packages:** Use the starter template (5 min setup)
2. **Existing packages:** Annual audit (find violations via CI)
3. **Contributors:** Document `git config core.hooksPath .githooks` in CONTRIBUTING.md

---

## Summary: What to Do Today

**If you have 1-2 existing packages:**
- Scan each for violations: `python3 .githooks/check_ascii.py --all`
- If violations found → Fix them (30-60 min)
- Add hook infrastructure (15 min)
- Update README.md (5 min)
- (Optional) Add or verify `.editorconfig` (5 min)
- Commit (2 min)
- **Total: 1-2 hours max**

**If you have many packages (5+):**
- Use phased approach above
- Week 1: High-priority packages (full remediation)
- Week 2+: Medium- and low-priority (just add hook)
- **Total: Spread over 2-3 weeks, ~30 min/package**

**If you're publishing a package soon:**
- Run scan before submission
- Fix violations now
- Add hook infrastructure
- Include in release notes (optional mention)

