# InntegerOS ISO Roadmap

**Target:** InntegerOS 1.0 with a tested, bootable, installable Kubuntu-based ISO by **November 27, 2026** (early November 28 is the contingency window).  
**Release rule:** the ISO is a 1.0 deliverable, not a later milestone. It must pass the live-session and installation gates below.

## Product direction

InntegerOS is intended to become an independently developed Linux distribution—not a Kubuntu respin with a new logo and wallpaper.

The project will build its own integrated desktop experience, system identity, Control Center, first-run flow, package/configuration manifest, update and recovery experience, live image, and installation workflow. It may reuse upstream components such as the Linux kernel, Ubuntu package infrastructure, and KDE Plasma. Reusing components is good engineering; outsourcing the entire product identity and experience to another distribution is not the goal.

## Desktop editions and Complete Edition vision

The first installable prototype focuses on **Plasma Edition**, the current development target. **GNOME Edition** is the first alternative workflow; **Xfce Edition** is the lightweight alternative. All three must use the same shared InntegerOS foundation, with separate desktop profiles and independent VM test coverage. The installer should select one desktop, defaulting to Plasma, rather than installing every desktop environment at once.

**InntegerOS: Complete Edition** is the long-term vision for a mature, fully integrated InntegerOS ecosystem, eventually including an InntegerOS-designed desktop environment. It is not a current release or a reason to delay the first Plasma live image. The project will first stabilize shared services and desktop integration, then prototype native desktop components only where justified.

See [Desktop Editions](DESKTOP-EDITIONS.md) for the detailed architecture and support gates.

**Base decision for 1.0:** use the official Kubuntu 26.04.1 LTS desktop ISO as the source image. Remaster it with the InntegerOS integration layer and preserve Kubuntu’s existing live-session, boot, and installer infrastructure wherever practical. The remaster toolchain still needs a working proof of concept.

## Milestones

- **Nov 18–20 — source-image and remaster proof of concept:** verify the official Kubuntu ISO checksum, inspect its boot/live/installer layout, choose a remastering method, and produce a minimal repeatable image.
- **Nov 21–23 — InntegerOS live session:** boot the remastered image in a disposable VM; test identity, networking, display scaling, audio, Control Center, stable features, experimental defaults, and offline usability.
- **Nov 24–25 — installation gate:** verify the inherited Kubuntu installer still launches and identifies the InntegerOS image correctly; test clean-disk installation and first boot in disposable VMs. Test alongside installation only when safely validated.
- **Nov 26 — release candidate:** rerun acceptance tests against the exact ISO, capture package inventory/build metadata/logs, generate SHA-256, and complete release notes.
- **After the shared foundation stabilizes:** add GNOME and Xfce edition profiles and run separate VM compatibility tests for each.

## Release gates

1. The build is repeatable from repository-controlled configuration.
2. The image boots in a clean virtual machine and reaches the InntegerOS desktop without requiring internet access for first boot.
3. InntegerOS owns the visible system identity, desktop defaults, first-run experience, and core integration.
4. Upstream notices, licences, and trademarks are handled correctly; the image does not imply official Kubuntu endorsement.
5. No credentials, personal files, machine-specific configuration, or private keys are baked into the image.
6. The installer is tested in disposable VMs and never silently partitions a disk.
7. Updates and basic recovery procedures are documented.
8. The published image has a checksum and clear hardware/support notes.
9. Every desktop edition advertised as supported has passed its own live-session, install, update, and post-install VM tests.

## Scope boundaries

- The **1.0 ISO is required**. Do not publish 1.0 as complete without the tested image.
- The first prototype should prioritize a reliable Plasma live system and safe installation over a custom partitioning engine or multiple desktop environments.
- Do not test installation on the user's daily-use dual-boot laptop until the image has passed VM testing and a separate backup/recovery plan is confirmed.
- If installation testing is not complete by the end of November, December's deliverable can be a live-image preview rather than an unsafe or untested installer.

## Current status — November 19, 2026

**Stage: source-image metadata verification implemented; remaster build still pending.** The official Kubuntu 26.04.1 LTS ISO and its SHA-256 are recorded in the manifest. `scripts/verify-kubuntu-source.sh` now checks the manifest against the official release's `SHA256SUMS` and, when given the ISO file, verifies the local image bytes too. An offline fixture test is included in CI. The repository still has no ISO remaster builder, and no InntegerOS ISO has been produced or boot-tested.

The next concrete deliverable is a repeatable disposable-environment remaster proof of concept. Before selecting extraction/rebuild commands, inspect the actual source image's boot catalog, filesystem layout, live filesystem, and installer launch path. Preserve those upstream paths, resolve package candidates against the matching repositories, and produce a bootable InntegerOS live image.

## Installation architecture

The product identity, desktop edition strategy, base-system strategy, installer requirements, and safety gates are documented in [Installation Design](INSTALLATION-DESIGN.md).

## 0.8 image-viewer track

In parallel with ISO planning, 0.8 targets a broad-format image-viewing experience, including animated formats. See [Image Viewer Compatibility](IMAGE-VIEWER.md) for scope and test gates. The image should include the tested viewer setup, but the build is not blocked on supporting every obscure format.
