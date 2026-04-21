function __fish_git_pad_command
    set -l cmd (commandline -pxc)
    test (count $cmd) -gt 1
    and contains -- $cmd[2] $argv
end

function __fish_git_pad_needs_command
    test (count (commandline -pxc)) -eq 1
end

function __fish_git_pad_issues
    set -l pad_dir (string join "/" (dirname (git rev-parse --path-format=absolute --git-common-dir)) ".git-pad/issues")

    test -d "$pad_dir"
    or return

    for f in (grep -l "status: \(open\|in-progress\)" $pad_dir/*.md)
        set -l issue (string match -r -g "$pad_dir/(.*)\\.md\$" $f)
        set -l desc (grep -m 1 '^title:' $f | string replace -m 1 "title: " "" | string shorten -m 35)

        printf "%s\t%s\n" $issue $desc
    end
end


# No files expansion
complete -c git-pad --no-files

# Simple commands
complete -c git-pad -n __fish_git_pad_needs_command -a init -x -d 'Initialize a new pad'
complete -c git-pad -n __fish_git_pad_needs_command -a status -x -d 'Show status'
complete -c git-pad -n __fish_git_pad_needs_command -a commit -x -d 'Commit changes'
complete -c git-pad -n __fish_git_pad_needs_command -a log -x -d 'Show log'
complete -c git-pad -n __fish_git_pad_needs_command -a list -x -d 'List issues'
complete -c git-pad -n __fish_git_pad_needs_command -a search -x -d 'Search issues'
complete -c git-pad -n __fish_git_pad_needs_command -a remove -x -d 'Remove an issue'
complete -c git-pad -n __fish_git_pad_needs_command -a clone -x -d 'Clone a pad'
complete -c git-pad -n __fish_git_pad_needs_command -a track -x -d 'Track an issue'
complete -c git-pad -n __fish_git_pad_needs_command -a remote -x -d 'Manage remotes'
complete -c git-pad -n __fish_git_pad_needs_command -a push -x -d 'Push changes'
complete -c git-pad -n __fish_git_pad_needs_command -a pull -x -d 'Pull changes'
complete -c git-pad -n __fish_git_pad_needs_command -a fetch -x -d 'Fetch changes'
complete -c git-pad -n __fish_git_pad_needs_command -a merge -x -d 'Merge changes'
complete -c git-pad -n __fish_git_pad_needs_command -a version -x -d 'Show version'

# Comments with issue expansion
complete -c git-pad -n __fish_git_pad_needs_command -a edit -x -d 'Edit an issue'
complete -c git-pad -n '__fish_git_pad_command edit' -a '(__fish_git_pad_issues)' -x -d Issue

complete -c git-pad -n __fish_git_pad_needs_command -a comment -x -d 'Add a comment'
complete -c git-pad -n __fish_git_pad_needs_command -a show -x -d 'Show an issue'
