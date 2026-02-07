*** comment by kwhk_gogpu@gangdong(kwonhyun.kim@gmail.com) at 2026-02-06 13:25:38

The output of `dirname "$(git rev-parse --git-common-dir)"` is just `.`.
You might do something like `$(pwd)/$(dirname $(git rev-parse --git-common-dir))` if the output is always relative to the current directory.
