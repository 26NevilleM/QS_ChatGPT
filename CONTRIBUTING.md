# Contributing Guide

## Prerequisites
- macOS or Linux  
- Git and GitHub access  
- Python 3.x available as `python3`
- (Optional) `make` and a terminal with zsh/bash

---

## Quick Start (TL;DR)

From the repo root:

```bash
# One-time bootstrap (installs pre-commit hook, backfills prompts, validates)
./scripts/one-shot-setup

# Optional flags
./scripts/one-shot-setup --push   # also commit & push changes
./scripts/one-shot-setup --force  # overwrite existing template/CI/Makefile if applicable
```

Create a feature branch and commit your changes:

```bash
git checkout -b feat/my-change

# edit prompts / tools
git add -A
git commit -m "feat: my change"   # pre-commit will run fix+validate
git push
```

Open a Pull Request against `main` when ready.

---

## Makefile Shortcuts

```bash
make            # same as: make validate
make validate   # run checksums, build catalog, validate all
make checksums  # update checksums
make catalog    # rebuild catalog
make hooks      # (re)install pre-commit hook
```

---

## Tips & Troubleshooting

- Always run commands **from the repo root** (not `~`).
- If your commit didn’t trigger validation, reinstall the hook:
  ```bash
  make hooks
  ```
- If you pasted multi-line blocks with here‑docs earlier and saw prompts like `heredoc>`, make sure the block was properly closed; try again or restart the terminal session.
- Validations show a summary and `ALL_VALIDATIONS_OK` when everything passes.
