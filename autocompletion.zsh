_git_pad ()
{
    local cur prev words cword

    # _init_completion comes from bash-completion package.
    # Fall back to manual init if unavailable (e.g. macOS without bash-completion).
    if declare -f _init_completion > /dev/null 2>&1; then
        _init_completion || return
    else
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
        cur="${COMP_WORDS[$COMP_CWORD]}"
        prev="${COMP_WORDS[$COMP_CWORD-1]}"
    fi

    local subcommands="init edit status commit comment log list show search remove clone track remote push pull fetch merge version"

    # First argument after `pad`
    if [[ $cword -eq 2 ]]; then
        __gitcomp "$subcommands"
        return
    fi

    case "${words[2]}" in
        edit|show|comment)
            local common_dir="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
            local pad_dir="$common_dir/.git-pad/issues"

            [[ -d "$pad_dir" ]] || return

            local files=()
            while IFS= read -r f; do
                files+=( "${f%.md}" )
            done < <(cd "$pad_dir" && compgen -G "*.md")

            __gitcomp "${files[*]}"
            ;;
    esac
}