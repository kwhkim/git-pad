_git_pad ()
{
    local cur prev words cword

    # Manually initialize completion variables for portability
    # across Linux, macOS, and Git Bash (Windows).
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD
    cur="${COMP_WORDS[$COMP_CWORD]}"
    prev="${COMP_WORDS[$(( COMP_CWORD - 1 ))]}"

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