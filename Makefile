PY ?= python3

.PHONY: default validate checksums catalog hooks help

default: validate

help:
	@echo "Targets:"
	@echo "  make            - default target (validate)"
	@echo "  make validate   - run checksums, catalog build, and validator"
	@echo "  make checksums  - update checksums"
	@echo "  make catalog    - rebuild catalog"
	@echo "  make hooks      - install git pre-commit hook"

validate: checksums catalog
	$(PY) Vault/tools/validate_all.py

checksums:
	$(PY) Vault/tools/update_checksums.py

catalog:
	$(PY) Vault/tools/build_catalog.py

hooks:
	@mkdir -p .git/hooks
	@printf '%s\n' \
		'#!/usr/bin/env bash' \
		'set -euo pipefail' \
		'python3 Vault/tools/update_checksums.py' \
		'python3 Vault/tools/build_catalog.py' \
		'python3 Vault/tools/validate_all.py' \
		> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "[hooks] pre-commit installed"
