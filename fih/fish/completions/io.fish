# FIH command and subcommand completions.
complete -c io -f
complete -c io -n '__fish_use_subcommand' -a 'help version info doctor update profile theme apps welcome blacklight config shell'
complete -c io -n '__fish_seen_subcommand_from update' -l check -d 'Check for source updates without applying them'
complete -c io -n '__fish_seen_subcommand_from profile' -a 'status apply restore' -d 'Desktop profile action'
