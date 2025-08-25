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
