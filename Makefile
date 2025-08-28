.PHONY: guard smoke followup

SANDBOX = Vault/Prompt_Library/sandbox/followup_generator/prompt.md
ACTIVE  = Vault/Prompt_Library/active/followup_generator/prompt.md

guard:
	./scripts/guard_prompt.sh $(SANDBOX)
	./scripts/guard_prompt.sh $(ACTIVE)

smoke:
	@echo '{"recipient":"Taylor","sender":"Neville","last_contact_days":7,"context":"Quick smoke of the pipeline."}' > /tmp/fg_case.json
	./scripts/run_followup.sh /tmp/fg_case.json | tee tests/.runs/$$(date +%Y%m%d-%H%M%S)_smoke.json

# Usage: make followup RECIP="Taylor" SENDER="Neville" DAYS=7 CTX="message context…"
followup:
	./scripts/compose_followup.sh "$(RECIP)" "$(SENDER)" $(DAYS) "$(CTX)" | tee tests/.runs/$$(date +%Y%m%d-%H%M%S)_followup.json

.PHONY: quick
# Usage: make quick RECIP="Taylor" SENDER="Neville" DAYS=7 CTX="context…"
quick:
	./scripts/compose_followup.sh "$(RECIP)" "$(SENDER)" $(DAYS) "$(CTX)" \
	| tee tests/.runs/$$(date +%Y%m%d-%H%M%S)_followup.json \
	| jq -r '.body' | pbcopy && echo "📋 Body copied to clipboard"

run:
	./scripts/compose_followup.sh "$(RECIP)" "$(SENDER)" $(DAYS) "$(CTX)" | tee tests/.runs/$$(date +%Y%m%d-%H%M%S)_followup.json
.PHONY: quick2
# Copies subject and body to two files and puts body on clipboard
quick2:
	./scripts/compose_followup.sh "$(RECIP)" "$(SENDER)" $(DAYS) "$(CTX)" \
	| tee tests/.runs/$$(date +%Y%m%d-%H%M%S)_followup.json \
	| jq -r '.subject,.body' > /tmp/followup.txt && pbcopy < /tmp/followup.txt && echo "📋 Subject+Body copied"
.PHONY: subject
subject:
	./scripts/compose_followup.sh "$(RECIP)" "$(SENDER)" $(DAYS) "$(CTX)" \
	| jq -r '.subject' | pbcopy && echo "📋 Subject copied"
triage:
	@./scripts/triage "$(CASE)"
# triage:
	@./scripts/triage "$(CASE)"

triage-case:
	@[ -n "$$CASE" ] || (echo "Usage: make triage-case CASE=tests/cases/ad_hoc.json" && exit 1)
	bin/beast-triage "$$CASE" | jq -r ".category,.urgency"

followup-case:
	@[ -n "$$CASE" ] || (echo "Usage: make followup-case CASE=tests/cases/ad_hoc.json" && exit 1)
	bin/beast-followup "$$CASE"

.PHONY: run-case
run-case:
	@[ -n "$$CASE" ] || (echo "Usage: make run-case CASE=tests/cases/ad_hoc.json" && exit 1)
	bin/beast "$$CASE"
