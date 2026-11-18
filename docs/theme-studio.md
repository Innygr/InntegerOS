# InntegerOS Theme Studio

A user-scoped GUI for applying desktop colour presets and opening KDE's native appearance settings.

## Install

From the repository root:

```bash
bash scripts/install-theme-studio.sh
```

Then search the KDE application launcher for **InntegerOS Theme Studio**. It requires Python 3 with Tkinter and KDE System Settings. On Kubuntu, install Tkinter if needed with `sudo apt install python3-tk`.

## Desktop theme presets

Theme Studio detects colour-scheme files already installed on the system and offers:

- **InntegerOS Dark** — the official violet/cyan `InnyGrOS` colour scheme.
- **Kubuntu Dark** — prefers a Kubuntu-provided dark scheme if present; otherwise uses Breeze Dark.
- **Breeze Light** — KDE's standard light colour scheme.
- **Breeze Dark** — KDE's standard dark colour scheme.
- **System Default / More Colour Schemes** — opens KDE's native Colors settings so the user can choose another installed scheme or restore their preferred default.

A preset changes only the KDE colour scheme. It does not change the wallpaper, icons, cursor, fonts, Plasma layout, login screen, or boot theme. If a scheme is not installed, Theme Studio reports that and opens KDE's colour settings; it does not download or install theme packages.

## Other appearance controls

- Wallpaper chooser using the existing InntegerOS wallpaper helper; falls back to KDE Wallpaper settings.
- KDE settings shortcuts for icons, cursors, global themes, and fonts.

## Uninstall

Remove the user-scoped launcher and app:

```bash
rm -f ~/.local/bin/integeros-theme-studio ~/.local/share/applications/integeros-theme-studio.desktop
rm -rf ~/.local/share/integeros/theme-studio
```

This does not undo appearance choices already made in KDE.
