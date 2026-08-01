#!/usr/bin/env python3
"""Guard against specific .gitignore rules that have silently reappeared before.

Background: this repo's .gitignore has twice accumulated a bare
'.posit/assistant' rule, which silently blocks new files under
.posit/assistant/ from ever being tracked even though that directory is
meant to be fully tracked as dev history (see AGENTS.md). The second
occurrence also came with an unanchored 'docs' rule, which -- lacking a
leading slash -- matched any directory named "docs" at any depth
(including .posit/assistant/docs/), not just the intended root-level
pkgdown build output. Both bugs are easy to reintroduce by accident (e.g.
copy-pasting an old .gitignore, or a stale Posit Assistant session
re-adding the line) and easy to miss because ignored files simply vanish
from `git status` without an error.

This hook checks the STAGED version of .gitignore (what will actually be
committed) for a small, explicit blocklist of known-bad rules. It is
intentionally narrow -- it does not try to detect "any" overly broad
pattern, only the two specific rules that have bitten this repo before.

Usage:
    check_gitignore.py --staged   # check staged .gitignore (for git hook)
    check_gitignore.py PATH       # check an explicit .gitignore-format file
"""
from __future__ import annotations

import subprocess
import sys

# Exact rules (after stripping a leading '!' negation and any trailing
# slash) that are forbidden anywhere in .gitignore.
FORBIDDEN_EXACT = {
    ".posit/assistant": (
        "blocks new files under .posit/assistant/ from ever being tracked "
        "-- that directory is meant to be fully tracked as dev history "
        "(see AGENTS.md). Remove this line; .Rbuildignore already excludes "
        "it from the built package."
    ),
    "docs": (
        "unanchored 'docs' matches any directory named docs at any depth "
        "(e.g. .posit/assistant/docs/), not just the root-level pkgdown "
        "build output. Use '/docs' instead."
    ),
}


def normalize(line: str) -> str:
    """Strip a leading negation and a single trailing slash for comparison."""
    stripped = line.strip()
    if stripped.startswith("!"):
        stripped = stripped[1:]
    if stripped.endswith("/") and len(stripped) > 1:
        stripped = stripped[:-1]
    return stripped


def scan_text(text: str) -> list[tuple[int, str, str]]:
    """Return (line number, offending line, reason) for each forbidden rule."""
    problems = []
    for lineno, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        key = normalize(line)
        if key in FORBIDDEN_EXACT:
            problems.append((lineno, raw_line, FORBIDDEN_EXACT[key]))
    return problems


def read_staged_content(path: str) -> str | None:
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
    if len(argv) != 2:
        print("Usage: check_gitignore.py --staged | PATH", file=sys.stderr)
        return 2

    if argv[1] == "--staged":
        text = read_staged_content(".gitignore")
    else:
        try:
            with open(argv[1], "r", encoding="utf-8") as fh:
                text = fh.read()
        except FileNotFoundError:
            text = None

    if text is None:
        return 0  # no .gitignore staged/found -- nothing to check

    problems = scan_text(text)
    if not problems:
        return 0

    print("\n\033[0;31mForbidden .gitignore rule(s) found:\033[0m")
    for lineno, raw_line, reason in problems:
        print(f"  line {lineno}: '{raw_line.strip()}'")
        print(f"    {reason}")
    print(
        "\n\033[0;31mERROR:\033[0m .gitignore contains a rule known to have "
        "silently hidden project files before. Fix the line(s) above, "
        "re-stage .gitignore, and commit again.\n"
        "To bypass in a rare, justified case: git commit --no-verify"
    )
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
