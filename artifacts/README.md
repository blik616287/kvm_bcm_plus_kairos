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

The playbook finds them by extension, so exact filenames don't matter:

```
artifacts/
├── palette-enterprise-appliance-<version>.tar.zst
├── palette-enterprise-appliance-<version>.tar.sig.bin
└── spectro_public_key.pem
```

Pin a specific file instead of auto-discovery with
`-e appliance_content_bundle=/path/to/bundle.tar.zst`.

Auto-discovery is only safe with **one** bundle present: the glob sorts
lexicographically, not by version, so `4.9.3` beats `4.11.0`. With more than
one, the run fails rather than guessing — pin the names in your profile.

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

Which files move is whatever the profile names —
`appliance_bundle_filename`, `appliance_bundle_signature_filename`,
`appliance_signing_key_filename`. The JFrog path and the local filename are
deliberately identical, which is what lets discovery above find a pulled file
with no further configuration. Leaving one empty drops it from the transfer.
A new Palette version is a copy of `profiles/palette-appliance.yml` with those
three names and `PE_VERSION` changed — see "Adding a version" there.

Verify a download before using it, per Spectro Cloud's bundle verification
instructions:

```bash
openssl dgst -sha256 -verify artifacts/spectro_public_key.pem \
  -signature artifacts/*.tar.sig.bin artifacts/*.tar.zst
# Verified OK
```

`roles/palette_cluster` performs this same check before uploading anything, and
fails the run if it does not pass.

`appliance_pe_version` in `inventory/hosts.yml` **must match** the stylus/agent
version your content bundle ships.

> **`appliance_pe_version` is the stylus *agent* version, not the bundle filename.**
> They differ. `palette-enterprise-appliance-4.10.17.tar.zst` ships stylus
> `v4.10.4` — `4.10.17` is the manifest version. Read the real one out of the
> bundle before setting it:
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
