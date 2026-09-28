# artifacts/

Licensed Spectro Cloud downloads for the **self-hosted Palette appliance**
(`make palette-appliance`). Everything in this directory is gitignored — these
files are licensed and large (the content bundle is ~10 GB), and none of it is
ours to redistribute.

Not needed for the BCM + Kairos pipeline (stages 1–6); only
`playbooks/palette-appliance.yml` reads this directory.

Obtain them from [Artifact Studio](https://artifact-studio.spectrocloud.com),
which requires a customer login; ask your Spectro Cloud representative or open
a support ticket for access. Under **Install Palette Enterprise**, select your
version and show the artifacts, then download:

| File | Required |
|---|---|
| Content bundle, `*.tar.zst` | yes |
| Its detached signature, `*.tar.sig.bin` | recommended |
| Content-signing public key, `*.pem` | recommended |

```
artifacts/
├── palette-enterprise-appliance-<version>.tar.zst
├── palette-enterprise-appliance-<version>.tar.sig.bin
└── spectro_public_key.pem
```

Each file is resolved in three steps, most specific first:

1. an **explicit path** — `appliance_content_bundle`,
   `appliance_content_bundle_signature`, `appliance_signing_public_key`, for a
   file kept outside this directory;
2. the **configured name** under `appliance_artifacts_dir`, when that file is
   there — `appliance_bundle_filename` and friends, derived from
   `appliance_bundle_version`;
3. **glob by extension**, which is the hand-copied case where the names were
   never configured.

Step 3 is only safe with **one** bundle present: the glob sorts
lexicographically, not by version, so `4.9.3` beats `4.11.0`. With more than one
and no name or path configured, the run fails rather than guessing.

All of these are **group_vars**, defaulted in `inventory/hosts.yml` and overridden
in `inventory/group_vars/all.yml`. None of it lives in a profile, so pointing a
build at a different version or a differently-named mirror is a config change,
not an edit to a committed file.

## Getting them here without hand-copying 10 GB

Once someone has downloaded a version from Artifact Studio, mirror it to JFrog
so no one repeats the download:

```bash
make palette-artifacts-push    # artifacts/ -> JFrog (explicit; licensed content)
make palette-artifacts-pull    # JFrog -> artifacts/
```

An appliance build pulls automatically for anything `artifacts/` is missing, so
on a fresh rig `make palette-appliance` fetches what it needs and proceeds.
Files already present are never re-downloaded.

This uses the same credential as the stage-1 BCM ISO download
(`jfrog_token` in the gitignored `inventory/group_vars/all.yml`) and the same
instance, but a different repo — a content bundle is not an ISO release:

| Variable | Default |
|---|---|
| `appliance_jfrog_instance` | `{{ jfrog_instance }}` |
| `appliance_jfrog_repo` | `palette-content` |
| `appliance_jfrog_token` | `{{ jfrog_token }}` |

Which files move is `appliance_bundle_filename`,
`appliance_bundle_signature_filename` and `appliance_signing_key_filename` — all
derived from `appliance_bundle_version`, all group_vars. The JFrog path and the
local filename are deliberately identical, which is what lets discovery above
find a pulled file with no further configuration. Leaving one empty drops it from
the transfer, so a site that mirrors only the bundle still works.

**Moving to a new Palette version** is therefore two keys in
`inventory/group_vars/all.yml`:

```yaml
appliance_bundle_version: "4.11.0"      # the .tar.zst filename
appliance_pe_version:     "v4.11.0"     # the stylus agent INSIDE it — check it
```

Copy `profiles/palette-appliance.yml` only to run two versions side by side on one
rig, where each build needs its own BCM-side namespace; a profile is passed with
`-e`, so its pins deliberately beat group_vars.

Verify a download before using it, per Spectro Cloud's bundle verification
instructions:

```bash
openssl dgst -sha256 -verify artifacts/spectro_public_key.pem \
  -signature artifacts/*.tar.sig.bin artifacts/*.tar.zst
# Verified OK
```

`roles/palette_cluster` performs this same check before uploading anything, and
fails the run if it does not pass.

`appliance_pe_version` (defaulted in `inventory/hosts.yml`, set in
`inventory/group_vars/all.yml`) **must match** the stylus/agent version your
content bundle ships.

> **Two different version numbers. Everything that matters uses the second one.**
>
> | | Example | Where it comes from |
> |---|---|---|
> | package / bundle version | `4.10.17` | the `.tar.zst` filename and the bundle manifest |
> | **stylus agent version** | **`v4.10.4`** | inside the bundle — this is what you configure |
>
> `palette-enterprise-appliance-4.10.17.tar.zst` ships stylus `v4.10.4`. One
> setting carries it: **`appliance_pe_version`**, which must be the *stylus*
> version and never the filename. Both images derive from it —
> `profiles/palette-appliance.yml` and `profiles/edge-to-appliance.yml` each pass
> `PE_VERSION: "{{ appliance_pe_version }}"` to CanvOS — and
> `playbooks/tasks/appliance_credentials.yml` checks it against the bundle before
> anything is built.
>
> That single source replaced three separate literals, because a mismatch never
> fails the build: it surfaces much later as a broken cluster deploy, or as an
> endless upgrade loop (`failed to upgrade stylus`) on an edge host that reports
> `healthy` and `ready`. With the edge copy simply unset, CanvOS used its own
> default — `v4.10.0-rc.2` was observed in exactly that state.
>
> Read the real value out of the bundle rather than off the filename:
>
> ```bash
> python3 playbooks/files/bundle_stylus_version.py artifacts/<bundle>.tar.zst
> ```
>
> or the long form:
>
> ```bash
> python3 - <<'EOF'
> import sys, json; sys.path.insert(0, 'roles/palette_cluster/files')
> from extract_spc import stream_members
> for _, d in stream_members('artifacts/<bundle>.tar.zst', names={"index.json"}):
>     for m in json.loads(d)["manifests"]:
>         a = m.get("annotations", {}) or {}
>         if a.get("io.image.ref.spectrocloud.type") == "stylus":
>             print(a["org.opencontainers.image.ref.name"])
>     break
> EOF
> ```
