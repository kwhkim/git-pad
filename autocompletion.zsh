if [[ -n "${ZSH_VERSION:-}" ]]; then
    autoload -Uz compinit && compinit

    _git_pad_zsh() {
        local state
        local -a subcommands
        subcommands=(
            'init:Initialize a new pad'
            'edit:Edit an issue'
            'status:Show status'
            'commit:Commit changes'
            'comment:Add a comment'
            'log:Show log'
            'list:List issues'
            'show:Show an issue'
            'search:Search issues'
            'remove:Remove an issue'
            'clone:Clone a pad'
            'track:Track an issue'
            'remote:Manage remotes'
            'push:Push changes'
            'pull:Pull changes'
            'fetch:Fetch changes'
            'merge:Merge changes'
            'version:Show version'
        )

        _arguments \
            '1: :->subcmd' \
            '*: :->args'

        case $state in
            subcmd)
                _describe 'subcommand' subcommands
                ;;
            args)
                case $words[2] in
                    edit|show|comment)
                        local common_dir pad_dir
                        common_dir="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)" 2>/dev/null)" || return
                        pad_dir="$common_dir/.git-pad/issues"
                        [[ -d "$pad_dir" ]] || return
                        local -a files
                        files=( "$pad_dir"/*.md )
                        files=( "${files[@]##*/}" )
                        files=( "${files[@]%.md}" )
                        _describe 'issue' files
                        ;;
                esac
                ;;
        esac
    }

    _git-pad() { _git_pad_zsh }
    compdef _git_pad_zsh git-pad
    zstyle ':completion:*:*:git:*' user-commands pad:'manage git pad issues'

    # Override oh-my-zsh's tag-order which restricts to common-commands only
    zstyle ':completion:*:*:git:*' tag-order user-commands common-commands

else
    _git_pad ()
    {
        local cur prev words cword

        cword="${COMP_CWORD:-0}"
        words=("${COMP_WORDS[@]}")
        cur="${words[$cword]}"
        if (( cword > 0 )); then
            prev="${words[$(( cword - 1 ))]}"
        else
            prev=""
        fi

        local subcommands="init edit status commit comment log list show search remove clone track remote push pull fetch merge version"

        if [[ $cword -eq 2 ]]; then
            __gitcomp "$subcommands"
            return
        fi

        case "${words[2]}" in
            edit|show|comment)
                local common_dir
                common_dir="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
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
fi