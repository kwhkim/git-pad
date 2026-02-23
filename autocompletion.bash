#_git_pad() {
#  __gitcomp "init edit status commit comment log list show search remove clone track remote push pull fetch merge version"
#}

_git_pad ()
{
    local cur prev words cword
    _init_completion || return

    local subcommands="init edit status commit comment log list show search remove clone track remote push pull fetch merge version"

    # First argument after `pad`
    if [[ $cword -eq 2 ]]; then
        __gitcomp "$subcommands"
        return
    fi

    case "${words[2]}" in
        edit|show|comment)
            #local common_dir="$(__git_common_dir)" || return
            local common_dir="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
            local pad_dir="$common_dir/.git-pad/issues"
            
            [[ -d "$pad_dir" ]] || return
            
            # # Complete filenames from $pad_dir
            # local IFS=$'\n'
            # local files=( $(cd "$pad_dir" && printf '%s\n' *.md) )
            
            local files=()
            while IFS= read -r f; do
                files+=( "${f%.md}" )
            done < <(cd "$pad_dir" && compgen -G "*.md")

            __gitcomp "${files[*]}"
            ;;
    esac
}
