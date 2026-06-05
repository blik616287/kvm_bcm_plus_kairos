# Build profiles

Reproducible per-OS-version variable files for the Kairos pipeline. Each file is
a complete set of extra-vars for one profile; pass it to **every** make stage
with `ANSIBLE_ARGS="-e @profiles/<file>.yml"`. They replace the ad-hoc
`-e @/tmp/*.json` files used during bring-up so a clean checkout reproduces the
same builds.

| Profile | File | Base image | Node |
|---------|------|-----------|------|
| Ubuntu 24.04 | `ubuntu-24.04.yml` | Spectro curated (auto) | node001 |
| Ubuntu 26.04 | `ubuntu-26.04.yml` | **self-built** (see below) | node002 |

## Prerequisites (clean environment)

1. `inventory/group_vars/all.yml` populated from `all.example.yml` — including, for
   the local-KVM path, the JFrog vars used by `bcm-prepare` to fetch the BCM ISO:
   `jfrog_token`, `jfrog_instance`, `jfrog_repo`, `iso_filename`.
2. For **26.04 only**: a self-built Kairos core base, because Spectro does not
   publish a curated `kairos-ubuntu:26.04-core-...`. Build + push it once and
   `docker login` so earthly can pull it:
   ```bash
   make kairos-base-push \
     BASE_OS_IMAGE=ubuntu:26.04 \
     KAIROS_BASE_VER=26.04 \
     KAIROS_BASE_REGISTRY=<your-registry-host>/<repo>
   docker login <your-registry-host>
   ```
   Then set `kairos_canvos_args.BASE_IMAGE` in `ubuntu-26.04.yml` to the exact
   pushed tag. (24.04 needs none of this.)

## Full local-KVM run from clean

```bash
# One-time shared infra
make install-deps
make bcm-prepare        # downloads + remasters the BCM ISO (needs jfrog_* in all.yml)
make bcm-vm             # installs BCM in KVM

# Build both images (coexist via distinct profile + ISO_NAME)
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"

# Deploy both to the BCM (additive, profile-namespaced)
make deploy-dd ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make deploy-dd ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"

# Boot + validate. NOTE: the local QEMU socket network serves ONE compute node
# at a time, so do them sequentially (stop one before booting the other).
make kairos-vm ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make validate  ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
# stop node001's VM, then:
make kairos-vm ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make validate  ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
```

For a remote BCM (no local KVM) run only `kairos-build`, `deploy-dd`, `validate`
with the same `-e @profiles/<file>.yml`.

## Reproducing the base image tag

The 26.04 `BASE_IMAGE` tag pattern is
`kairos-ubuntu:<ver>-core-amd64-generic-<KAIROS_VERSION>`, where `KAIROS_VERSION`
(default `v4.0.3`) and the kairos-init version come from the `Makefile`. Bump
`KAIROS_VERSION` / `KAIROS_INIT_VERSION` there and in the tag together.
