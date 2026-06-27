SHELL := /bin/bash
.DEFAULT_GOAL := help
ANSIBLE_ARGS ?=

E2E_DIR := $(shell pwd)
export E2E_DIR

LOGS_DIR := $(E2E_DIR)/logs

# Verbosity passthrough for any stage, e.g. `make deploy-dd V=-vv` (empty = normal).
V ?=

# Run a stage playbook with rich, retained logging (plan Part D):
#  - a timestamped per-run dir logs/run-<ts>/ (+ a `latest` symlink) so reruns
#    never clobber a prior run's evidence;
#  - ANSIBLE_LOG_PATH -> a structured ansible log in that dir, capturing every
#    task/result incl. delegated BCM/Kairos hosts (profile_tasks adds timings);
#  - console tee'd to BOTH the run dir and the flat logs/<stage>.log (back-compat
#    with `make *-serial`, docs, and the old paths).
define run_playbook
	@mkdir -p $(LOGS_DIR)
	@RUN_TS=$$(date +%Y%m%d-%H%M%S); RUN_DIR="$(LOGS_DIR)/run-$$RUN_TS"; \
	  mkdir -p "$$RUN_DIR"; ln -sfn "run-$$RUN_TS" "$(LOGS_DIR)/latest"; \
	  echo "==> logs: $$RUN_DIR  (symlinked as $(LOGS_DIR)/latest)"; \
	  set -o pipefail; \
	  ANSIBLE_LOG_PATH="$$RUN_DIR/$(1).ansible.log" \
	    ansible-playbook playbooks/$(1).yml $(V) $(ANSIBLE_ARGS) 2>&1 \
	    | tee "$$RUN_DIR/$(1).console.log" "$(LOGS_DIR)/$(1).log"
endef

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ---- Prerequisites ----

.PHONY: setup
setup: ## Verify prerequisites (ansible, qemu, docker, sshpass, etc.)
	@echo "Checking prerequisites..."
	@command -v ansible-playbook >/dev/null || { echo "MISSING: ansible"; exit 1; }
	@command -v qemu-system-x86_64 >/dev/null || { echo "MISSING: qemu-system-x86_64"; exit 1; }
	@command -v docker >/dev/null || { echo "MISSING: docker"; exit 1; }
	@command -v sshpass >/dev/null || { echo "MISSING: sshpass"; exit 1; }
	@command -v xorriso >/dev/null || { echo "MISSING: xorriso"; exit 1; }
	@command -v lz4 >/dev/null || { echo "MISSING: lz4"; exit 1; }
	@command -v jq >/dev/null || { echo "MISSING: jq"; exit 1; }
	@test -f inventory/group_vars/all.yml || { echo "MISSING: inventory/group_vars/all.yml (copy from all.example.yml)"; exit 1; }
	@echo "All prerequisites OK"

.PHONY: install-deps
install-deps: ## Install all build dependencies
	$(call run_playbook,install-dependencies)

# ---- Code quality: lint / format / static analysis ----
# Real .sh scripts shellcheck/shfmt directly; bash inside *.sh.j2 templates goes
# through scripts/shellcheck-templates.sh (renders then shellchecks). Gates
# ratchet via SHELLCHECK_SEVERITY (error -> warning -> style). See plan Part C.
SHELLCHECK_SEVERITY ?= error
SH_FILES = $(shell git ls-files '*.sh' | grep -v -E '^(CanvOS/|build/|dist/|logs/)')

.PHONY: lint
lint: ## Lint bash (.sh + .sh.j2), YAML, and Ansible
	@mkdir -p $(LOGS_DIR)
	@set -o pipefail; { \
	  echo "== shellcheck (real .sh) =="; \
	  test -z "$(SH_FILES)" || shellcheck -x --severity=$(SHELLCHECK_SEVERITY) $(SH_FILES); \
	  echo "== shellcheck (.sh.j2 templates) =="; \
	  scripts/shellcheck-templates.sh --severity=$(SHELLCHECK_SEVERITY); \
	  echo "== yamllint =="; yamllint -c .yamllint . ; \
	  echo "== ansible-lint =="; ansible-lint ; \
	} 2>&1 | tee $(LOGS_DIR)/lint.log

.PHONY: fmt
fmt: ## Auto-format all real .sh scripts (shfmt, in place)
	test -z "$(SH_FILES)" || shfmt -i 4 -ci -bn -sr -w $(SH_FILES)

.PHONY: fmt-check
fmt-check: ## Check .sh formatting without writing (CI/gate)
	test -z "$(SH_FILES)" || shfmt -i 4 -ci -bn -sr -d $(SH_FILES)

.PHONY: analyze
analyze: ## Static analysis: secrets (gitleaks) + IaC (checkov) + Python (bandit/vulture)
	@mkdir -p $(LOGS_DIR)
	@set -o pipefail; { \
	  echo "== gitleaks (BLOCKING) =="; gitleaks detect --config .gitleaks.toml --redact -v --no-banner; \
	  echo "== checkov (soft-fail during rollout) =="; checkov --config-file .checkov.yaml || true; \
	  echo "== bandit (Python; none yet) =="; bandit -r . -c pyproject.toml -q 2>/dev/null || true; \
	} 2>&1 | tee $(LOGS_DIR)/analyze.log

.PHONY: lint-fix
lint-fix: fmt ## Apply safe auto-fixes (shfmt format; ansible-lint --fix)
	ansible-lint --fix || true

# ---- Discovery ----

.PHONY: discover
discover: ## Discover BCM head node config (interactive)
	ANSIBLE_RESULT_FORMAT=yaml ansible-playbook playbooks/discover-bcm.yml

# ---- Pipeline (run in order) ----

.PHONY: bcm-prepare
bcm-prepare: ## Stage 1: Download + patch + remaster BCM ISO
	$(call run_playbook,01-bcm-prepare)

.PHONY: bcm-vm
bcm-vm: ## Stage 2: Launch BCM in local KVM, install, boot from disk
	$(call run_playbook,02-bcm-vm)

.PHONY: kairos-build
kairos-build: ## Stage 3: Build Kairos ISO + raw disk image
	$(call run_playbook,03-kairos-build)

.PHONY: kairos-image
kairos-image: ## Stage 3 (image-only / day-2): build + push container image, skip raw disk
	@mkdir -p $(LOGS_DIR)
	ansible-playbook playbooks/03-kairos-build.yml -e kairos_build_raw_disk=false $(ANSIBLE_ARGS) 2>&1 | tee $(LOGS_DIR)/03-kairos-image.log

# ---- Custom Kairos base image (for OS versions Spectro hasn't published) ----
# Build a Kairos "core" base from an upstream OS image via kairos-init, for use
# as a CanvOS .arg BASE_IMAGE override (e.g. Ubuntu 26.04). Override any var:
#   make kairos-base BASE_OS_IMAGE=ubuntu:26.04 KAIROS_BASE_REGISTRY=ttl.sh
BASE_OS_IMAGE        ?= ubuntu:26.04
KAIROS_INIT_VERSION  ?= v0.13.0
KAIROS_VERSION       ?= v4.0.3
KAIROS_BASE_REGISTRY ?= ttl.sh
KAIROS_BASE_REPO     ?= kairos-ubuntu
KAIROS_BASE_VER      ?= 26.04
KAIROS_BASE_TAG      ?= $(KAIROS_BASE_VER)-core-amd64-generic-$(KAIROS_VERSION)
KAIROS_BASE_IMAGE    ?= $(KAIROS_BASE_REGISTRY)/$(KAIROS_BASE_REPO):$(KAIROS_BASE_TAG)

.PHONY: kairos-base
kairos-base: ## Build a custom Kairos core base from BASE_OS_IMAGE (e.g. ubuntu:26.04) via kairos-init
	docker build \
	  --build-arg BASE_IMAGE=$(BASE_OS_IMAGE) \
	  --build-arg KAIROS_INIT_VERSION=$(KAIROS_INIT_VERSION) \
	  --build-arg KAIROS_VERSION=$(KAIROS_VERSION) \
	  -t $(KAIROS_BASE_IMAGE) \
	  -f files/kairos-base/Dockerfile files/kairos-base
	@echo ""
	@echo "Built $(KAIROS_BASE_IMAGE)"
	@echo "Push:  make kairos-base-push   (or: docker push $(KAIROS_BASE_IMAGE))"
	@echo "Then set in inventory/group_vars/all.yml:"
	@echo "  kairos_canvos_args:"
	@echo "    OS_DISTRIBUTION: ubuntu"
	@echo "    OS_VERSION: \"$(KAIROS_BASE_VER)\""
	@echo "    BASE_IMAGE: \"$(KAIROS_BASE_IMAGE)\""

.PHONY: kairos-base-push
kairos-base-push: kairos-base ## Build + push the custom Kairos base image
	docker push $(KAIROS_BASE_IMAGE)

.PHONY: deploy-dd
deploy-dd: ## Stage 4: Upload image to BCM, configure PXE
	$(call run_playbook,04-deploy-dd)

.PHONY: kairos-vm
kairos-vm: ## Stage 5: PXE boot Kairos compute VM
	$(call run_playbook,05-kairos-vm)

.PHONY: validate
validate: ## Stage 6: Validation
	$(call run_playbook,06-validate)

# ---- Full pipeline ----

.PHONY: all
all: ## Run full pipeline (stages 1-6)
	$(call run_playbook,site)

# ---- VM Management ----

.PHONY: bcm-stop
bcm-stop: ## Stop BCM VM
	@PID=$$(cat build/.bcm-qemu.pid 2>/dev/null) && kill $$PID 2>/dev/null || true
	@ps aux | grep '[q]emu-system.*BCM-HeadNode' | awk '{print $$2}' | xargs -r kill 2>/dev/null || true
	@echo "BCM VM stopped"

.PHONY: kairos-stop
kairos-stop: ## Stop Kairos compute VM
	@PID=$$(cat build/.kairos-qemu.pid 2>/dev/null) && kill $$PID 2>/dev/null || true
	@ps aux | grep '[q]emu-system.*Kairos-ComputeNode' | awk '{print $$2}' | xargs -r kill 2>/dev/null || true
	@echo "Kairos VM stopped"

.PHONY: stop
stop: bcm-stop kairos-stop ## Stop all VMs

.PHONY: bcm-serial
bcm-serial: ## Tail BCM serial log
	@tail -f logs/bcm-serial.log 2>/dev/null || echo "No serial log found"

.PHONY: kairos-serial
kairos-serial: ## Tail Kairos serial log
	@tail -f logs/kairos-serial.log 2>/dev/null || echo "No serial log found"

# ---- Cleanup ----

.PHONY: clean
clean: ## Remove build/, logs/
	ansible localhost -m file -a "path=$(E2E_DIR)/build state=absent" --become
	ansible localhost -m file -a "path=$(E2E_DIR)/logs state=absent" --become

.PHONY: clean-dist
clean-dist: ## Remove downloaded ISOs (dist/)
	ansible localhost -m file -a "path=$(E2E_DIR)/dist state=absent" --become

.PHONY: clean-canvos
clean-canvos: ## Remove cloned CanvOS repo + per-profile raw build artifacts
	ansible localhost -m file -a "path=$(E2E_DIR)/CanvOS state=absent" --become
	@find $(E2E_DIR)/build -maxdepth 1 -type f \( -name '*-disk.raw' -o -name '*-disk.raw.lz4' -o -name '*-disk.raw.sha256' \) -delete 2>/dev/null || true

.PHONY: clean-all
clean-all: stop clean clean-dist clean-canvos ## Stop VMs + remove everything

.PHONY: teardown
teardown: ## Stop VMs + remove build artifacts (keeps dist/ and CanvOS/)
	@$(MAKE) --no-print-directory stop
	ansible localhost -m file -a "path=$(E2E_DIR)/build state=absent" --become
	ansible localhost -m file -a "path=$(E2E_DIR)/logs state=absent" --become
