# FIH — Fish Integrated by Blacklight

FIH is the optional Team Blacklight shell integration for InntegerOS. It customizes the upstream fish shell and provides the `io` command dispatcher. It does not fork fish.

## Design guarantees

- No InntegerOS account, Team Blacklight account, activation, subscription, or online login.
- No telemetry or background network requests from FIH.
- User-scoped installation; no root privileges required.
- Does not change the user's default login shell.
- Does not overwrite an existing custom fish prompt.
- Does not silently install packages or change system settings.
- Ordinary fish commands remain available.

## Install on Kubuntu

Install fish through Discover or APT, then from the InntegerOS checkout:

```bash
sudo apt install fish
bash fih/install.sh
fish
io help
```

The installer places the dispatcher in `~/.local/bin/io`, fish startup configuration and completions in `~/.config/fish`, and a small local config file in `~/.local/share/integeros/fih`.

If the user already has a custom fish prompt, it is preserved. The FIH prompt is installed as `fih_prompt`; use `functions -c fih_prompt fish_prompt` for the current session to try it. When no custom prompt exists, FIH enables its own prompt by default.

## Command reference

| Command | Purpose |
|---|---|
| `io help` | Show help |
| `io version` | Show FIH and InntegerOS versions |
| `io info` | Display local OS, kernel, host, desktop and shell information |
| `io doctor` | Run the existing read-only InntegerOS health check |
| `io update --check` | Check InntegerOS source updates without applying them |
| `io update` | Open the existing interactive source updater |
| `io profile status` | Inspect the current desktop profile |
| `io profile apply` | Run the existing reversible profile workflow |
| `io profile restore` | Restore the saved profile |
| `io theme` | Open Theme Studio or KDE System Settings |
| `io apps` | Open KDE Discover |
| `io welcome` | Open the InntegerOS Welcome Center |
| `io blacklight` | Open Blacklight Desktop Suite |
| `io config` | Open KDE System Settings |
| `io shell` | Start a login fish session |

The dispatcher calls existing InntegerOS components; it does not reimplement their settings logic. Some commands therefore require the matching InntegerOS application or checkout to be installed.

## Uninstall

Remove FIH's user-scoped files:

```bash
rm -f ~/.local/bin/io ~/.config/fish/conf.d/fih.fish \
  ~/.config/fish/completions/io.fish ~/.config/fish/functions/fih_prompt.fish
rm -rf ~/.local/share/integeros/fih
```

If FIH created `~/.config/fish/functions/fish_prompt.fish` on a machine without an existing custom prompt, remove that wrapper too. This does not uninstall fish or change the login shell.

## Release scope

FIH 0.1 provides the branded greeting, selectable prompt, command completions, local `io` command dispatcher, and user-scoped installer. Later work can add richer completions, more InntegerOS subcommands, integration tests against Kubuntu/Plasma, and packaging.
