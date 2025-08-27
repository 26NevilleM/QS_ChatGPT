SLUG ?= followup_generator

.PHONY: test publish release drift catalog

test:
	@scripts/all_tests.sh "$(SLUG)"

publish:
	@scripts/vault/promote_clean.sh -y "$(SLUG)"
	@scripts/all_tests.sh "$(SLUG)"

release:
	@scripts/release_prompt.sh "$(SLUG)"

drift:
	@scripts/vault/check_drift.sh "$(SLUG)"

catalog:
	@scripts/vault/rebuild_catalog.sh
