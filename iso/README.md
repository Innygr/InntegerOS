# InntegerOS ISO Build Area

**Status:** Kubuntu base selected; remaster build implementation and VM validation are still pending.

## First release target

- Architecture: x86_64 / amd64
- Desktop profile: Plasma
- Base image: **Kubuntu 26.04.1 LTS desktop ISO**
- Source image: `kubuntu-26.04.1-desktop-amd64.iso`
- Image type: InntegerOS-branded live image
- Installer: retain the installer shipped with the Kubuntu source image, subject to validation after remastering

InntegerOS 1.0 is intentionally building on Kubuntu rather than assembling a desktop distribution from a blank Ubuntu root filesystem. The source ISO already provides the Plasma live environment, boot layout, hardware enablement, and installation path. The remaster should preserve those working components wherever possible and add the InntegerOS layer.

Official source directory: https://cdimages.ubuntu.com/kubuntu/releases/26.04.1/release/

## Remastering goals

1. Download the official source ISO and verify it against its published SHA256SUMS file.
2. Inspect and record its live filesystem, boot configuration, installer, package inventory, and licences.
3. Apply InntegerOS packages, first-party applications, branding, desktop defaults, and feature policy to the live filesystem.
4. Keep the upstream boot and installer flow intact unless a tested requirement demands a change.
5. Rebuild a bootable hybrid ISO and record the exact source ISO hash, repository commit, package inventory, build log, and output hash.
6. Test the resulting artifact in disposable UEFI VMs before publishing it.

The exact remastering toolchain is not yet selected. A prototype must demonstrate that it can preserve Kubuntu's boot and installer behaviour; merely extracting and recompressing a filesystem is not sufficient.

## Planned layout

- `manifest.json` — machine-readable base, build, installer, and artifact identity
- `manifests/` — explicit base and edition package lists
- `profiles/` — desktop-specific package and configuration profiles
- `hooks/` and `config/` — narrowly scoped image customizations
- `build/` — generated configuration/output only; never commit large generated ISOs
- `../scripts/iso-preflight.sh` — read-only structural validation
- `../tests/iso-manifest-smoke.py` — CI validation

## Feature policy

Stable features form the default experience. Experimental features may be shipped in the image, but must be disabled by default, visibly labelled **EXPERIMENTAL**, and enabled only through an explicit user action. Experimental components must not be required for boot, login, networking, updates, recovery, or normal desktop use. See [Experimental Feature Policy](../docs/EXPERIMENTAL-FEATURES.md).

## Build safety

- Build in a disposable VM or dedicated clean build environment, never by modifying a daily-use installation.
- The live preview must not write to internal disks.
- Never include personal home-directory content, account credentials, SSH keys, browser profiles, Wi-Fi credentials, cloud tokens, or machine-specific state.
- Keep package manifests and non-secret build logs for every prototype.
- Publish a checksum for every image artifact.
- Do not claim installer or dual-boot support until the exact remastered ISO passes disposable-VM tests.

## Current gate

The next deliverable is a minimal remaster prototype based on the selected Kubuntu ISO. Run `bash scripts/iso-preflight.sh` and `python3 tests/iso-manifest-smoke.py` from the repository root to validate metadata; these checks do not build an image. See [Image-Build Tool Evaluation](../docs/IMAGE-BUILD-TOOLS.md) and [ISO Roadmap](../docs/ISO-ROADMAP.md).
