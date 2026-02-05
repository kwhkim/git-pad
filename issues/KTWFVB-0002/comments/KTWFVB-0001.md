*** comment by kwhkim(kwonhyun.kim@gmail.com) at 2026-02-06 02:50:06

Changed `for f in "$issues_dir"/*.md; do`...`done | sort` to `while IFS= read -r -d '' f; do`...`done < <(find "$issues_dir" -maxdepth 1 -name "*.md" -type f -printf '%T@ %p\0' | sort -zrn | cut -zd' ' -f2-)`

But it is not solved.
