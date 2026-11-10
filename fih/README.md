# FIH — Fish Integrated by Blacklight

**FIH** is the Team Blacklight customization and InntegerOS command layer for the [fish shell](https://fishshell.com/). It is an InntegerOS component, not a fork or replacement implementation of fish.

## Principles

- No account, activation, subscription, telemetry, or mandatory cloud service.
- Local-first: FIH commands operate on the installed computer.
- Fish remains fish: standard fish syntax, built-ins, plugins, and completions continue to work.
- Safe defaults: the installer is user-scoped, does not use `sudo`, and does not change the account's login shell.
- GUI-first: commands such as `io apps`, `io theme`, and `io config` open graphical applications.

## Install

From the InntegerOS repository root:

```bash
sudo apt install fish
bash fih/install.sh
fish
io help
```

The installer copies FIH's dispatcher to `~/.local/bin/io` and installs fish startup configuration and completions under `~/.config/fish`. It does not install packages, edit system files, or change the default login shell.

If a custom `fish_prompt.fish` already exists, the installer preserves it. The FIH prompt is installed as an optional prompt file instead.

## Commands

| Command | Action |
|---|---|
| `io help` | Show command reference |
| `io version` | Show FIH and InntegerOS versions |
| `io info` | Show local OS, kernel, host, desktop and shell information |
| `io doctor` | Run the InntegerOS health check |
| `io update --check` | Check for InntegerOS source updates |
| `io profile status` | Inspect the current desktop profile |
| `io profile apply` | Start the existing reversible profile workflow |
| `io profile restore` | Restore the saved desktop profile |
| `io theme` | Open Theme Studio, or KDE System Settings |
| `io apps` | Open Discover |
| `io welcome` | Open the InntegerOS Welcome Center |
| `io blacklight` | Open Blacklight Desktop Suite |
| `io config` | Open KDE System Settings |
| `io shell` | Start a login fish session |

Some commands require their corresponding InntegerOS component to be installed. Missing components produce a clear error instead of silently installing packages.

## Uninstall

```bash
rm -f ~/.local/bin/io ~/.config/fish/conf.d/fih.fish ~/.config/fish/completions/io.fish ~/.config/fish/functions/fish_prompt.fih.fish
rm -rf ~/.local/share/integeros/fih
```

This removes FIH files only. It does not uninstall fish, alter KDE settings, or change the login shell. If you opted to use the FIH prompt by copying it to `fish_prompt.fish`, remove or restore that file separately.

## Status

FIH 0.1 is the initial usable foundation. It provides the local command dispatcher, fish greeting, optional prompt, completions, and user-scoped installer. InntegerOS component integration and test coverage will expand before the cousin-ready build.
