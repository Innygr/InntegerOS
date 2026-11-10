function fih_prompt
    set -l last_status $status
    set_color brmagenta
    printf '╭─ '
    set_color brcyan
    printf '%s@%s' (whoami) (prompt_hostname)
    set_color normal
    printf ' '
    set_color brblue
    printf '%s' (prompt_pwd)
    set_color normal
    if test $last_status -ne 0
        set_color brred
        printf ' [%s]' $last_status
        set_color normal
    end
    printf '\n'
    set_color brmagenta
    printf '╰─> '
    set_color normal
end
