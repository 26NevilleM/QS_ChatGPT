# QS_ChatGPT

![Vault smoketests](https://github.com/26NevilleM/QS_ChatGPT/actions/workflows/vault-smoketests.yml/badge.svg?branch=main)

A small, batteries‑included repo for managing a prompt “Vault”, helper tools, and lightweight CI checks. It ships with a one‑shot setup script, a pre‑commit hook that validates your prompt library, and a Makefile with handy targets.

---

## What’s in here?

- `Vault/Prompt_Library/` – packs (each has a `meta.json` and `prompt.md`)
- `Vault/tools/` – helper scripts (checksums, catalog builder, validators, scaffolding)
- `scripts/one-shot-setup` – installs pre‑commit, runs fixers/validators once
- `.github/workflows/vault-smoketests.yml` – CI for basic validation
- `Makefile` – friendly wrappers around the tools

---

## Requirements

- macOS or Linux
- Git + GitHub access
- Python 3.x available as `python3`
- (Optional) `make`

---

## Quick Start

From the repo root:

```bash
# One-time bootstrap (installs pre-commit hook, backfills prompts, validates)
./scripts/one-shot-setup

# Optional flags
./scripts/one-shot-setup --push   # also commit & push changes
./scripts/one-shot-setup --force  # overwrite existing template/CI/Makefile if applicable
```

Make a change flow:

```bash
git checkout -b feat/my-change

# edit prompts / tools
git add -A
git commit -m "feat: my change"   # pre-commit will run fix+validate
git push
```

---

## Makefile targets

```bash
make            # same as: make validate
make validate   # run checksums, build catalog, validate all
make checksums  # update checksums
make catalog    # rebuild catalog
make hooks      # (re)install pre-commit hook
```

---

## Working with packs

Scaffold from a CSV (example):

```bash
python3 Vault/tools/bulk_scaffold.py packs.csv --category sandbox
# add --force to overwrite if re-running
```

Validate locally before pushing:

```bash
make validate
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
