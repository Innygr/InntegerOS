# FIH // Team Blacklight — user-scoped fish integration.
# This file intentionally makes no network calls and does not change the login shell.
if status is-interactive
    if not set -q FIH_GREETED
        set -g FIH_GREETED 1
        set_color brmagenta
        echo "╭─ FIH // TEAM BLACKLIGHT"
        set_color normal
        set_color brcyan
        echo "│  InntegerOS Integrated Shell"
        set_color normal
        echo "╰─ No account. No activation. Your system, your rules."
        echo
    end
end

# Add the FIH command dispatcher to the PATH when installed.
set -l fih_bin "$HOME/.local/bin"
if test -d "$fih_bin"; and not contains -- "$fih_bin" $PATH
    fish_add_path --global "$fih_bin"
end
