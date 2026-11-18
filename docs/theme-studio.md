# InntegerOS Theme Studio

A user-scoped GUI for applying paired light/dark desktop colour presets and opening KDE's native appearance settings.

## Install

From the repository root:

```bash
bash scripts/install-theme-studio.sh
```

Then search the KDE application launcher for **InntegerOS Theme Studio**. The installer also installs the official InntegerOS Light and Dark colour schemes into the user's KDE colour-scheme directory. It backs up an existing scheme file before replacing it.

## Light and dark presets

Each theme family has both modes:

- **InntegerOS Light** — custom bright palette with violet selection and cyan interaction accents.
- **InntegerOS Dark** — official deep navy, violet and cyan palette.
- **Kubuntu Light / Dark** — uses a Kubuntu-specific scheme if installed; falls back to Breeze Light / Dark.
- **Breeze Light / Dark** — KDE's standard light and dark schemes.

Theme Studio detects installed schemes and shows availability. It never downloads themes or installs packages automatically. Applying a preset changes only the KDE colour scheme; wallpaper, icons, cursor, fonts, Plasma layout, login screen and boot theme remain unchanged.

## Other appearance controls

Shortcuts open KDE settings for wallpaper, icons, global themes and fonts. The wallpaper action uses the existing InntegerOS wallpaper helper when available.

## Uninstall

Remove the user-scoped launcher and app:

```bash
rm -f ~/.local/bin/integeros-theme-studio ~/.local/share/applications/integeros-theme-studio.desktop
rm -rf ~/.local/share/integeros/theme-studio
```

The installed colour schemes and current KDE appearance are left in place.
