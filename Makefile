.PHONY: install dry-run uninstall list validate update outdated vendored

# Extra targets, e.g. `make install TARGETS="cursor opencode"`
TARGETS ?=
TARGET_FLAGS := $(foreach t,$(TARGETS),--target $(t))

install: validate
	scripts/install.sh $(TARGET_FLAGS)

dry-run:
	scripts/install.sh --dry-run $(TARGET_FLAGS)

uninstall:
	scripts/install.sh --uninstall $(TARGET_FLAGS)

list:
	scripts/install.sh --list $(TARGET_FLAGS)

validate:
	scripts/validate.sh

# Third-party skills (vendor.sources / vendor.lock).
# `make update` pulls every source; `make update ONLY=mattpocock/skills` or
# `ONLY=humanizer` limits it. Then review `git diff skills/` and commit.
ONLY ?=
update:
	node scripts/vendor.mjs update $(ONLY)
	scripts/validate.sh
	scripts/install.sh
	@git status --short -- skills vendor.lock

outdated:
	node scripts/vendor.mjs outdated

vendored:
	node scripts/vendor.mjs list
