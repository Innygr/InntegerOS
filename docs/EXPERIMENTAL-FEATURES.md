# InntegerOS Experimental Feature Policy

**Policy for InntegerOS 1.0:** experimental features may be included in the ISO, but they are **disabled by default** and visibly labelled **EXPERIMENTAL**.

## User-facing rules

1. Every experimental feature must be identified in the shared registry at `config/features.json`.
2. The default state must be disabled for a fresh install and a live session.
3. The Control Center must display an unmistakable **EXPERIMENTAL** badge beside the feature name and explain that it is not part of the stable baseline.
4. Enabling a feature requires a deliberate, explicit user action. No bulk opt-in, silent activation, or automatic enablement during first boot.
5. The user must be able to turn the feature off again. Where a feature changes system configuration, provide a safe disable/rollback path.
6. Experimental components must not be required for boot, login, networking, audio, updates, recovery, or ordinary desktop operation.
7. A failed experimental component must not prevent the stable desktop or Control Center from opening.
8. Release notes must list experimental features, their limitations, and any known recovery steps.

## Stability categories

| Category | Default state | Presentation |
|---|---|---|
| Stable | Enabled when part of the standard experience | Normal feature entry |
| Optional stable | Not installed or activated until requested | Normal entry marked Optional |
| Experimental | **Disabled** | **EXPERIMENTAL** badge and warning |
| Deprecated | Disabled / unavailable | **DEPRECATED** label and migration note |

Optional does not automatically mean experimental. A mature optional application or package bundle can remain optional without an experimental warning.

## Initial registry

The initial registry in `config/features.json` records the features already explicitly described as experimental in the project documentation:

- Experimental GRUB Boot Manager
- Experimental Blacklight Lock Screen Overlay

Both are marked `default_enabled: false`. Additional features must be added to the registry before being shipped as experimental in the release image.

## Release gate

The registry is the source of truth for image composition and the Control Center's experimental labels. Before 1.0:

- the image build must preserve the disabled defaults;
- the Control Center must read or otherwise stay synchronized with the registry;
- fresh live sessions and installations must verify that experimental features remain off;
- each experimental feature must show the badge and require explicit opt-in;
- disable/rollback behaviour must be tested where applicable.

A registry entry alone does not prove runtime enforcement. Do not mark this policy implemented until the live image and Control Center pass these checks.
