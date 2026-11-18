# InntegerOS Theme Studio

A user-scoped GUI for coordinating KDE desktop appearance with the optional InntegerOS login and boot themes.

## Install

From the repository root:

```bash
bash scripts/install-theme-studio.sh
```

Then search the KDE application launcher for **InntegerOS Theme Studio**. The installer adds the official InntegerOS Light and Dark colour schemes and bundles the guarded SDDM/Plymouth installers plus their theme assets inside the user-scoped application directory.

## Desktop colour presets

Each family has both modes:

- **InntegerOS Light** — bright palette with violet selection and cyan interaction accents.
- **InntegerOS Dark** — deep navy, violet and cyan palette.
- **Kubuntu Light / Dark** — uses a Kubuntu-specific scheme if installed; otherwise uses Breeze Light / Dark.
- **Breeze Light / Dark** — KDE's standard schemes.

Theme Studio detects installed schemes. It does not download third-party themes or install packages automatically.

## Plasma appearance

The Plasma Appearance section opens KDE System Settings directly for:

- Application Style (widget/control appearance)
- Plasma Splash Screen (the screen shown while the Plasma desktop session starts)
- Global Theme, icons, cursors, fonts, and wallpaper

These are native KDE settings modules. Theme Studio opens them rather than silently replacing system-wide theme files. The selected application style or splash theme must already be installed.

## Login and boot experience

The optional buttons install the repository's **Blacklight Matrix** themes:

- **SDDM Login Screen** — graphical login greeter. Requires SDDM; not compatible with GDM.
- **Plymouth Boot Splash** — animation shown while Linux starts. Updates initramfs and appears on the next boot.

Each button opens Konsole and runs the existing guarded installer with `sudo`. Read the terminal output and type the install confirmation when prompted. The scripts refuse unsafe overwrites, and the Plymouth installer saves the previously selected theme for restoration. These actions are independent: changing SDDM does not change Plymouth, and neither changes the Plasma session splash.

To restore the previous setup, run the corresponding command from the repository checkout:

```bash
sudo bash scripts/login-theme.sh uninstall
sudo bash scripts/boot-animation.sh uninstall
```

The uninstall commands have their own confirmation prompts. For recovery instructions and compatibility notes, see [login theme](login-theme.md) and [boot animation](boot-animation.md).

## Limitations

- Login and boot themes are experimental and require real-hardware validation.
- SDDM theme changes take effect when the greeter next appears; Theme Studio does not restart the display manager.
- Plymouth changes require rebuilding initramfs (handled by its installer) and appear on the next boot.
- Application Style and Plasma Splash Screen selection are managed by KDE System Settings; Theme Studio does not install arbitrary third-party styles.
- The colour preset buttons change only the KDE colour scheme. They do not automatically switch the application style, wallpaper, icons, login screen, Plasma splash, or boot splash.

## Uninstall Theme Studio

Remove the user-scoped launcher and app:

```bash
rm -f ~/.local/bin/integeros-theme-studio ~/.local/share/applications/integeros-theme-studio.desktop
rm -rf ~/.local/share/integeros/theme-studio
```

The installed colour schemes and currently selected desktop/login/boot appearance are left in place. Use the dedicated uninstall commands above to restore SDDM or Plymouth.
