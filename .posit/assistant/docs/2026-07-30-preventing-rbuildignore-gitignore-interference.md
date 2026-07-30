# Posit Assistant sometimes edits .Rbuildignore / .gitignore

**Date:** 2026-07-30

Posit Assistant occasionally adds `.posit/assistant` to `.Rbuildignore` and
`.gitignore` on its own. Two things about that, for this project specifically:

- **`.Rbuildignore`:** `^\.posit$` already excludes `.posit/assistant/`, so a
  second `^\.posit/assistant$` line is redundant but harmless — cosmetic only,
  not worth engineering around.
- **`.gitignore`:** This one matters. `.posit/assistant/` holds the plans and
  docs from this AI-assisted build and is meant to stay in git history as a
  record of the process — at least until the package work is done, at which
  point these files get copied elsewhere and removed from the repo on
  purpose, by hand. An automatic `.gitignore` entry would silently stop new
  files from being tracked before that point, which defeats the purpose.

**Fix, if it happens again:** just revert and recommit.

```bash
git checkout .Rbuildignore .gitignore
```

No hooks, config files, or extra tooling needed for this — reverting when it
happens is simpler than trying to preemptively block it.
