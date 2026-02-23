#compdef git-pad

_git_pad() {
  local -a subcommands
  subcommands=(
    init
    edit
    status
    commit
    comment
    log
    list
    show
    search
    remove
    clone
    track
    remote
    push
    pull
    fetch
    merge
    version
  )

  # First argument after git-pad
  if (( CURRENT == 2 )); then
    _values 'subcommand' $subcommands
    return
  fi

  case $words[2] in
    edit|show|comment)
      local common_dir
      common_dir="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")" || return

      local pad_dir="$common_dir/.git-pad/issues"
      [[ -d $pad_dir ]] || return

      local -a files
      files=(${pad_dir}/*.md(N:t:r))

      _values 'issue' $files
      ;;
  esac
}

compdef _git_pad git-pad
