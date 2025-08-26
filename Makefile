.PHONY: vault-index vault-lint pack-export pack-import pack-list
# Root Makefile
SHELL := /bin/sh

include mk/docs.mk


include mk/dev.mk

vault-init:
	chmod +x scripts/vault/vault_init.sh scripts/vault/vault_tree.sh scripts/vault/vault_lint.sh scripts/vault/vault_backup.sh
	scripts/vault/vault_init.sh

vault-tree:
	scripts/vault/vault_tree.sh


vault-index:
	scripts/vault/vault_index.sh

vault-lint:
	scripts/vault/vault_lint.sh
	make vault-index

pack-export:
	@scripts/vault/pack_export.sh

pack-import:
	@scripts/vault/pack_import.sh $(FILE)

pack-list:
	@scripts/vault/pack_list.sh
