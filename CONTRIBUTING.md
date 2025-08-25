# Contributing Guide

## Prerequisites
- macOS or Linux  
- git and GitHub access  
- Python 3.x available as `python3`

## Optional but handy
- make (predefined targets included)  
- Terminal with zsh/bash  

---

## Quick Start (TL;DR)

From the repo root:

```bash
# One-time bootstrap (installs pre-commit hook, backfills prompts, validates)
./scripts/one-shot-setup

# Optional flags
./scripts/one-shot-setup --push   # also commit & push changes
./scripts/one-shot-setup --force  # overwrite existing template/CI/Makefile if applicable

# Create a new feature branch
git checkout -b feat/my-change

# Edit prompts / tools
git add -A
git commit -m "feat: my change"   # pre-commit will run fix+validate
git push
```
