# Image package manifests

Package lists define image composition and remain separate from desktop profiles and build-tool configuration.

## Rules

- One package name per line.
- Blank lines and lines beginning with # are comments.
- Keep shared packages separate from edition-specific packages.
- Document non-obvious package choices in the corresponding profile.
- Do not include personal files or machine-specific configuration.
- Avoid meta-packages that pull in a second desktop environment.
- Record package sources and version policy in build metadata.
- Treat every list as a proposal until the image build and clean-VM test pass.

## Current proposal files

- base/common.txt — shared system utilities and services.
- profiles/plasma/packages.txt — initial Plasma Edition package candidates.
- optional/development.txt — opt-in development tools.
- optional/creative.txt — opt-in creative applications.
- optional/gaming.txt — opt-in gaming tools; some packages may require additional repository components.

The shared base and Plasma package lists are now consumed by the ISO provisioner and are mandatory for the default Plasma image. A successful build must resolve every package name against the Kubuntu repositories; unavailable packages fail the build. The optional development, creative, and gaming bundles remain opt-in and are excluded from the default ISO.

## Next validation

1. Build the image using the Kubuntu live filesystem and its configured Ubuntu repositories.
2. Resolve every required package; fail closed if any package cannot be installed.
3. Inspect dependency closure and identify packages pulled in by dependencies.
4. Capture the installed package inventory in the image build metadata.
5. Test the live desktop and installer in disposable UEFI VMs.

Optional bundles must never be included in the minimal base image by default.
