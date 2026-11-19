# InntegerOS Image-Build Approach

**Decision:** use the official Kubuntu 26.04.1 LTS desktop ISO as the source image for InntegerOS 1.0.  
**Implementation status:** remastering toolchain not yet selected; no InntegerOS ISO has been built.

## Why this approach

The current InntegerOS desktop is developed on Kubuntu and depends heavily on KDE Plasma and the Ubuntu/Kubuntu package ecosystem. Rebuilding the entire live system from a generic Ubuntu root filesystem would add unnecessary work and risk for the 1.0 deadline.

Instead, start with the Kubuntu desktop ISO and add the InntegerOS layer. The project should preserve the upstream live environment, kernel and initramfs, bootloader configuration, hardware support, and graphical installer wherever practical. InntegerOS supplies its own product identity, defaults, first-party applications, Control Center, feature policy, and release metadata.

The selected source image is:

- Release: Kubuntu 26.04.1 LTS (Resolute Raccoon)
- Architecture: amd64
- Filename: `kubuntu-26.04.1-desktop-amd64.iso`
- Official directory: https://cdimages.ubuntu.com/kubuntu/releases/26.04.1/release/
- Published SHA-256: `831e4d4bb85098339ba43d3502cd6619b27e76daf37246a084cd68a6413090b8`

Always download the checksum file from the same official release directory and verify the source image before modifying it.

## Required remaster capabilities

The selected toolchain must:

1. Extract and modify the Kubuntu live filesystem without losing required filesystem metadata.
2. Install packages from the selected Kubuntu/Ubuntu repositories using repository-controlled manifests.
3. Apply InntegerOS system identity, desktop defaults, first-party apps, branding, and experimental-feature defaults.
4. Preserve the source ISO's UEFI boot support and hybrid-media behaviour.
5. Preserve the existing Kubuntu live-session and installer launch path unless a separately tested change is required.
6. Rebuild a bootable ISO and verify its boot catalog, filesystem layout, and checksum.
7. Capture exact package versions, source ISO hash, source commit, tool versions, logs, and final artifact hash.

A successful root-filesystem build alone does not prove that the ISO boots or that its installer still works.

## Toolchain evaluation

The proof of concept should compare only approaches that can modify and rebuild the existing Kubuntu desktop ISO:

- **ISO remaster with filesystem extraction/reassembly:** likely the most direct route, but must preserve boot catalog, EFI images, file permissions, symlinks, hard links, and hybrid boot metadata.
- **live-build with Kubuntu-specific integration:** a possible controlled rebuild route, but only if it can consume the selected Kubuntu package set and reproduce the same live desktop and installer behaviour.
- **Ubuntu live-image tooling:** useful reference material for understanding Ubuntu live filesystems and hooks; do not assume Canonical's full image publication pipeline is available to this project.

Do not select a tool based on popularity or a successful generic Linux ISO. Run a minimal prototype against the exact Kubuntu 26.04.1 source image.

## Installer policy

The 1.0 target is to retain the installer provided by the Kubuntu source image rather than introduce a new installer backend. First identify the actual installer components and launch configuration in the downloaded source image. After remastering, verify that the live desktop still launches the installer and that the installer identifies the InntegerOS target correctly where practical.

The installer must clearly identify the target disk and require explicit final confirmation before destructive changes. Test clean-disk installation only in disposable VMs. Test alongside installation only in a disposable VM containing a second OS. If the inherited installer cannot safely meet a requirement, disable that option rather than claiming it works.

## Acceptance gates

- Source ISO checksum verified against the official checksum file.
- Source package inventory and boot/installer structure recorded.
- Remaster configuration stored in this repository.
- Build succeeds from a clean checkout and records all inputs.
- Result boots in a disposable UEFI VM into a usable InntegerOS Plasma live session.
- Live session works offline for basic desktop use and does not alter disks by itself.
- Control Center opens; stable features work; experimental features are disabled by default and visibly labelled.
- Inherited installer still launches and passes clean-disk installation tests in a disposable VM.
- Installed system boots and identifies itself as InntegerOS.
- Final tested ISO hash matches the published artifact hash.

No builder has yet passed these gates. The manifest deliberately records the method as selected while the implementation remains `not_started`.
