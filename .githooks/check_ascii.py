#!/usr/bin/env python3
"""Detect non-ASCII characters in R package source/documentation files.

Design goal: be ROBUST. The previous approach embedded literal Unicode
characters inside a bash character class (``grep -q '[""'']'``). That
bracket expression silently corrupted into matching plain ASCII quotes
(editors/shells mangle raw multi-byte literals inside quoted strings very
easily), which caused false positives on every normal string literal and
trained everyone to bypass the hook with --no-verify.

This script sidesteps that entire failure mode: it never encodes "bad"
characters as literals to match against. Instead it decodes each file as
UTF-8 and flags any character whose code point is outside the ASCII range
(0-127). Because the comparison is a numeric check (``ord(ch) > 127``)
rather than a hand-typed pattern, there is nothing here that a shell,
editor, or copy-paste can silently corrupt.

Usage:
    check_ascii.py --staged                 # scan staged files (for git hook)
    check_ascii.py file1.R file2.Rmd ...    # scan explicit files (manual/CI)
"""
from __future__ import annotations

import subprocess
import sys
import unicodedata

# File extensions that matter for R CMD check / CRAN portability.
CHECKED_SUFFIXES = (".R", ".r", ".Rmd", ".rmd", ".Rnw", ".Rd", ".qmd")
CHECKED_BASENAMES = {"DESCRIPTION", "NAMESPACE"}

# Paths that legitimately contain non-ASCII and should never be checked:
# raw source data (original-language CSVs), lockfiles, and internal
# planning notes (not shipped as part of the package).
EXCLUDED_PREFIXES = (
    "inst/extdata/",
    "data-raw/",
    "data/",
    ".posit/",
    "renv/",
)
EXCLUDED_FILES = {"renv.lock"}

# Best-effort ASCII suggestions for common "smart typography" characters.
REPLACEMENTS = {
    "\u2013": "-",    # en dash
    "\u2014": "-",    # em dash
    "\u2018": "'",    # left single quote
    "\u2019": "'",    # right single quote
    "\u201c": '"',    # left double quote
    "\u201d": '"',    # right double quote
    "\u2026": "...",  # horizontal ellipsis
    "\u00a0": " ",    # non-breaking space
    "\u2022": "-",    # bullet
    "\u2212": "-",    # minus sign
    "\u2192": "->",   # rightwards arrow
    "\u2190": "<-",   # leftwards arrow
}


def suggest_ascii(ch: str) -> str | None:
    """Return a best-effort ASCII replacement for a non-ASCII character."""
    if ch in REPLACEMENTS:
        return REPLACEMENTS[ch]
    # Fall back to stripping accents, e.g. e-acute -> e, c-cedilla -> c.
    decomposed = unicodedata.normalize("NFKD", ch)
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    if stripped and stripped.isascii():
        return stripped
    return None


def should_check(path: str) -> bool:
    if path in EXCLUDED_FILES:
        return False
    if any(path.startswith(prefix) for prefix in EXCLUDED_PREFIXES):
        return False
    basename = path.rsplit("/", 1)[-1]
    if basename in CHECKED_BASENAMES:
        return True
    return path.endswith(CHECKED_SUFFIXES)


def scan_text(text: str) -> list[tuple[int, int, str]]:
    """Return (line, col, character) for every non-ASCII character."""
    problems = []
    for lineno, line in enumerate(text.splitlines(), start=1):
        for col, ch in enumerate(line, start=1):
            if ord(ch) > 127:
                problems.append((lineno, col, ch))
    return problems


def report(path: str, text: str) -> bool:
    """Print a diagnosis for a single file. Returns True if issues found."""
    problems = scan_text(text)
    if not problems:
        return False

    lines = text.splitlines()
    print(f"\n\033[0;31mNon-ASCII characters found in: {path}\033[0m")
    for lineno, col, ch in problems[:20]:
        name = unicodedata.name(ch, "UNKNOWN CHARACTER")
        suggestion = suggest_ascii(ch)
        hint = f" -> suggest '{suggestion}'" if suggestion else " (no automatic suggestion)"
        context = lines[lineno - 1].strip()
        print(f"  line {lineno}, col {col}: U+{ord(ch):04X} '{ch}' ({name}){hint}")
        print(f"    {context}")
    if len(problems) > 20:
        print(f"  ... and {len(problems) - 20} more occurrence(s)")
    return True


def get_staged_files() -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
        capture_output=True,
        text=True,
        check=True,
    )
    return [p for p in result.stdout.splitlines() if p]


def read_staged_content(path: str) -> str | None:
    """Read the staged (index) version of a file, not the working tree copy.

    This matters for partially-staged files (git add -p): we must check what
    will actually be committed, not what happens to be on disk.
    """
    result = subprocess.run(
        ["git", "show", f":{path}"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        return None
    return result.stdout


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: check_ascii.py --staged | file1 [file2 ...]", file=sys.stderr)
        return 2

    if argv[1] == "--staged":
        candidates = [p for p in get_staged_files() if should_check(p)]
        reader = read_staged_content
    else:
        candidates = argv[1:]
        def reader(path: str) -> str | None:
            try:
                with open(path, "r", encoding="utf-8") as fh:
                    return fh.read()
            except (FileNotFoundError, UnicodeDecodeError):
                return None

    found_issues = False
    for path in candidates:
        text = reader(path)
        if text is None:
            continue
        if report(path, text):
            found_issues = True

    if found_issues:
        print(
            "\n\033[0;31mERROR:\033[0m Non-ASCII characters found in the files above.\n"
            "R CMD check and CRAN require ASCII-only source/documentation files.\n"
            "Apply the suggested replacements, re-stage, and commit again.\n"
            "To bypass in a rare, justified case: git commit --no-verify"
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
