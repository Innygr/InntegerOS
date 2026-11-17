# InntegerOS release metadata

The graphical software updater reads `release/latest.json` from the official
InntegerOS repository. This file is the single stable-channel announcement
point for the OS release version and review page.

## Publishing a release

When a release is ready:

1. Update the root `VERSION` file.
2. Update `version`, `status`, `url`, and `notes` in `latest.json`.
3. Publish the matching GitHub release and attach verified installation
   artifacts plus SHA-256 checksums.
4. Ensure the release notes describe supported upgrade paths and any required
   backup/recovery steps.

The software manager compares the installed version with this metadata and
notifies the user when the published version is newer. It opens the official
release page for review. It does not download, replace system files, repartition
disks, or run an unattended OS upgrade.

APT package updates remain a separate, explicitly approved system-maintenance
workflow. Repository source updates are also separate from full OS releases.
