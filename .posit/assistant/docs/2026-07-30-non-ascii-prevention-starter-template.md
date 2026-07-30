# Non-ASCII Prevention: Starter Template for New R Packages

**Date:** 2026-07-30  
**Purpose:** Reusable setup instructions for adding robust non-ASCII character detection to new R packages before the first commit.

---

## Problem Statement

R CMD check fails on non-ASCII characters in R code, Rmd files, and DESCRIPTION files. These are invisible when editing (curly quotes, em-dashes, accented characters slip in from copy-paste, autocorrect, or system locale defaults). By the time they're caught, they're already committed to history.

The pressfreedom.data package discovered that naive pre-commit hooks (using bash character classes) **silently fail** — they corrupt over time and train developers to use `git commit --no-verify`, defeating the entire purpose.

---

## Solution: Three Files (Copy-Paste Ready)

### 1. `.githooks/check_ascii.py` — The Scanner

Copy this file to **every new R package** at `.githooks/check_ascii.py`:

```python
#!/usr/bin/env python3
"""
Detect non-ASCII characters in staged R package files.

Rationale: R CMD check and CRAN reject non-ASCII in code. Bash character
classes (grep '[""'']') corrupt silently and fail to detect many violations.
This pure-Python numeric approach (ord(ch) > 127) is reliable and portable.

Files checked: *.R, *.Rmd, *.Rnw, *.Rd, *.qmd, DESCRIPTION, NAMESPACE
Files excluded: inst/extdata/ (raw data, legitimately non-ASCII), data/,
  data-raw/, renv.lock, .posit/, .github/
"""

import sys
import subprocess
import unicodedata
from pathlib import Path

# File patterns to check (relative to repo root)
PATTERNS_TO_CHECK = [
    "*.R",
    "*.Rmd",
    "*.Rnw",
    "*.Rd",
    "*.qmd",
    "DESCRIPTION",
    "NAMESPACE",
    "R/*.R",
    "man/*.Rd",
    "vignettes/*.Rmd",
]

# Directories to skip entirely
DIRS_TO_SKIP = {".git", ".github", "inst/extdata", "data", "data-raw",
                "renv", ".posit", ".Rproj.user", "node_modules"}

# ASCII replacement suggestions for common violations
REPLACEMENTS = {
    0x2013: ("en-dash", "–", "-"),           # – -> -
    0x2014: ("em-dash", "—", "-"),           # — -> -
    0x201C: ("left curly quote", """, '"'),  # " -> "
    0x201D: ("right curly quote", """, '"'), # " -> "
    0x2018: ("left single quote", "'", "'"), # ' -> '
    0x2019: ("right single quote", "'", "'"),# ' -> '
    0x2192: ("right arrow", "→", "->"),      # → -> ->
    0x00E9: ("e with acute", "é", "e"),     # é -> e
}

def should_skip_path(path_str):
    """Check if a path should be skipped (excluded directories)."""
    parts = Path(path_str).parts
    return any(part in DIRS_TO_SKIP for part in parts)

def get_staged_files(check_all=False):
    """Get list of staged files via git."""
    if check_all:
        cmd = ["git", "ls-files"]
    else:
        cmd = ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"]
    
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    return [f for f in result.stdout.split("\n") if f and not should_skip_path(f)]

def matches_pattern(filepath, patterns):
    """Check if filepath matches any pattern."""
    path_obj = Path(filepath)
    for pattern in patterns:
        if path_obj.match(pattern):
            return True
    return False

def check_file_for_ascii(filepath):
    """Check a single file for non-ASCII characters."""
    violations = []
    
    try:
        if "--staged" in sys.argv:
            # Get content from git index (staged)
            result = subprocess.run(
                ["git", "show", f":{filepath}"],
                capture_output=True,
                text=True,
                check=False
            )
            if result.returncode != 0:
                return violations
            content = result.stdout
        else:
            # Get content from working directory
            with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
    except Exception as e:
        return [(filepath, 0, 0, f"Error reading file: {e}")]
    
    for line_num, line in enumerate(content.split('\n'), 1):
        for col_num, char in enumerate(line, 1):
            if ord(char) > 127:
                char_code = ord(char)
                try:
                    char_name = unicodedata.name(char)
                except ValueError:
                    char_name = f"U+{char_code:04X}"
                
                # Suggest replacement if available
                suggestion = ""
                if char_code in REPLACEMENTS:
                    desc, example, replace_with = REPLACEMENTS[char_code]
                    suggestion = f" (try: {replace_with})"
                
                violations.append({
                    'file': filepath,
                    'line': line_num,
                    'col': col_num,
                    'char': char,
                    'code': f"U+{char_code:04X}",
                    'name': char_name,
                    'suggestion': suggestion
                })
    
    return violations

def main():
    """Main entry point."""
    check_all = "--all" in sys.argv
    check_staged = "--staged" in sys.argv
    
    if check_all:
        files = get_staged_files(check_all=True)
    elif check_staged:
        files = get_staged_files(check_all=False)
    else:
        # Check modified files in working directory
        files = [f for f in Path(".").rglob("*") if f.is_file()]
    
    # Filter to relevant patterns
    files_to_check = [f for f in files if matches_pattern(f, PATTERNS_TO_CHECK)]
    
    all_violations = []
    for filepath in files_to_check:
        violations = check_file_for_ascii(filepath)
        all_violations.extend(violations)
    
    if all_violations:
        print("Non-ASCII characters detected:\n")
        for v in all_violations:
            if isinstance(v, dict):
                print(f"{v['file']}:{v['line']}:{v['col']}: {v['code']} ({v['name']}){v['suggestion']}")
            else:
                print(f"{v[0]}:{v[1]}:{v[2]}: {v[3]}")
        sys.exit(1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()
```

### 2. `.githooks/pre-commit` — The Hook

Copy this to `.githooks/pre-commit` (make executable):

```bash
#!/bin/bash
# Pre-commit hook: Check for non-ASCII characters in staged files.
# Setup: git config core.hooksPath .githooks

exec python3 "$(git rev-parse --git-dir)/../.githooks/check_ascii.py" --staged
```

After creating, make it executable:
```bash
chmod +x .githooks/pre-commit
```

### 3. `.github/workflows/ci-ascii-check.yaml` — Optional CI Check

If you want to catch violations in CI as well (for pull requests from forks):

```yaml
name: ASCII Check

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  ascii-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Check for non-ASCII characters
        run: python3 .githooks/check_ascii.py --all
```

---

## Setup Instructions for New Packages

### Step 1: Create Hook Directory and Files

```bash
# In your new package root
mkdir -p .githooks

# Copy the two files (or create them manually)
# 1. Add check_ascii.py (Python script above)
# 2. Add pre-commit (bash wrapper above)

chmod +x .githooks/pre-commit
```

**Note:** If your package already has `.editorconfig`, that's good—it sets editor defaults for UTF-8 encoding and line endings. The hook provides the actual enforcement at commit time. They work together as complementary layers.

### Step 2: Enable Hooks on First Clone

This is a **per-clone configuration** (hooks are versioned but not auto-enabled):

```bash
# After cloning your repo
git config core.hooksPath .githooks
```

Add to `.github/CONTRIBUTING.md` or `README.md` (Development section):

```markdown
### Development Setup

After cloning, enable pre-commit hooks:

```bash
git config core.hooksPath .githooks
```

This will automatically check for non-ASCII characters before every commit.
```

### Step 3: Document in README.md

Add a Development section:

```markdown
## Development

### Prerequisites

- Python 3.8+ (for pre-commit hooks)
- R 4.0+

### Setup

Clone the repo and configure git hooks:

```bash
git clone https://github.com/yourname/yourpkg.git
cd yourpkg
git config core.hooksPath .githooks
```

The hook will automatically prevent commits with non-ASCII characters in R code.
To bypass (not recommended): `git commit --no-verify`
```

### Step 4: Document Coding Standards

Add to `README.md` or create `CONTRIBUTING.md`:

```markdown
## Coding Standards

### Non-ASCII Policy

To pass R CMD check and maintain CRAN compliance, R code must be ASCII-only.

**Allowed:**
- ASCII hyphen: `2002-2026`
- ASCII dash: `Phase A - Download`
- ASCII arrow: `->`
- Straight quotes: `"..."`

**Not allowed:**
- En-dash/em-dash in text
- Curly quotes from copy-paste
- Accented characters in code
- Unicode arrows or symbols

The pre-commit hook will automatically detect violations. Fix before committing.
```

---

## What to Check (File Scope)

The scanner checks:
- `*.R` — R source files
- `*.Rmd` — R Markdown vignettes
- `*.Rnw` — Sweave files
- `*.Rd` — Roxygen documentation (generated)
- `*.qmd` — Quarto documents
- `DESCRIPTION`, `NAMESPACE` — Package metadata

The scanner explicitly **skips**:
- `inst/extdata/` — Raw data files (may be legitimately non-ASCII)
- `data/`, `data-raw/` — R data objects
- `renv.lock` — Package lock files
- `.github/`, `.posit/` — Configuration and internal notes

---

## Why This Approach

### Why Python, Not Bash?

- **Reliability:** Numeric character code comparison (`ord(ch) > 127`) never corrupts
- **Diagnostic power:** Automatic Unicode name lookup; helpful error messages
- **Portability:** Works on macOS, Linux, Windows without environment issues
- **Extensibility:** Easy to add file-specific rules, custom replacements

Bash character classes (`grep '[""'']'`) corrupt silently when copy-pasted or edited by different editors. This learned mistake (from pressfreedom.data) is why Python is the right choice.

### Why Both `.editorconfig` and the Hook?

They serve **complementary purposes**, not the same one:

- **`.editorconfig`:** Sets editor defaults (UTF-8 encoding, line endings, indentation)
  - Works when you save a file (soft prevention)
  - Helps across all EditorConfig-compatible editors
  - Cannot detect or block violations by itself

- **`.githooks/check_ascii.py`:** Detects and blocks non-ASCII at commit time (hard enforcement)
  - Works when you run `git commit` (prevents violations from entering history)
  - Catches violations that `.editorconfig` defaults didn't prevent
  - Provides diagnostic feedback (character code, name, suggestion)

**Recommendation:** Include both. `.editorconfig` in your package is a bonus—if you already have it, keep it. If not, you can add it later. The hook is the critical enforcement layer.

### Why `.githooks/` Directory?

- **Versioned:** Hooks survive fresh clones (unlike `.git/hooks/`)
- **Per-clone opt-in:** Simple `git config core.hooksPath` enables on each clone
- **CI-ready:** Can scan all files via `--all` flag in GitHub Actions

### Why Pre-commit + Optional CI?

- **Pre-commit:** Catches violations immediately (developer feedback loop)
- **CI (optional):** Catches violations in pull requests from forks (where pre-commit may not be configured)

---

## Testing Your Setup

### Test 1: False-Positive Regression (Normal Code Passes)

```r
# my_function.R
"This is a normal string with normal quotes"
x <- 2002-2026  # normal hyphen in comment
```

```bash
git add my_function.R
git commit -m "test: normal code should pass"
# Should succeed
```

### Test 2: Catch Real Violations

```r
# my_function.R
"This has curly quotes" <- 2023–2026  # en-dash in range
```

```bash
git add my_function.R
git commit -m "test: curly quotes and en-dash should fail"
# Should fail with diagnostic message
```

### Test 3: Bypass Hook (Not Recommended)

```bash
git commit --no-verify -m "bypass check (not recommended)"
# Will succeed even with violations
```

---

## Maintenance

### Update the Scanner

If you discover new problematic characters or need to adjust the file scope, edit `.githooks/check_ascii.py`:

1. Add new character codes to `REPLACEMENTS` dict
2. Adjust `PATTERNS_TO_CHECK` or `DIRS_TO_SKIP` as needed
3. Commit and push

All developers get the update automatically on next pull.

### Check Existing Code

Before first commit in a new package, scan all files:

```bash
python3 .githooks/check_ascii.py --all
```

Fix any violations before enabling the hook.

---

## Implementation Checklist for New Packages

- [ ] Create `.githooks/` directory
- [ ] Copy `check_ascii.py` to `.githooks/`
- [ ] Copy `pre-commit` to `.githooks/` and make executable
- [ ] (Optional) Create `.github/workflows/ci-ascii-check.yaml`
- [ ] Add setup instructions to `README.md` (Development section)
- [ ] Document coding standards in `CONTRIBUTING.md` or `README.md`
- [ ] Run `python3 .githooks/check_ascii.py --all` on existing code
- [ ] Commit all files (should pass the hook)
- [ ] Document in team/contributor guidelines: `git config core.hooksPath .githooks`

---

## FAQ

**Q: Why do I need to manually enable the hook with `git config`?**

A: Git doesn't auto-enable hooks from versioned directories for security (prevents arbitrary code execution on clone). One-time setup per clone is the standard practice. Document it in your README.

**Q: Can I use this with husky or other hook managers?**

A: Yes. If you use `husky`, you can call `.githooks/check_ascii.py --staged` from your husky config instead of using the pre-commit directly.

**Q: What if I need a non-ASCII character (like in a data comment)?**

A: Put it in `inst/extdata/` (explicitly excluded) or in a `.md` file outside the checked scope. Never in R code, `.Rd`, or `DESCRIPTION`.

**Q: Will this slow down commits?**

A: No. The check is O(n) in file size and typically completes in <100ms. Only staged files are checked (unless explicitly told otherwise).

---

## References

- **Original implementation:** pressfreedom.data package, commit bdc7aaf
- **Detailed analysis:** `.posit/assistant/docs/2026-07-30-non-ascii-prevention-v2.md`
