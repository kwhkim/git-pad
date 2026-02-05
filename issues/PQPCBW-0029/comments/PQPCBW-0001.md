Following script works,

```
  message="$(
  sed \
    -e "s/[[:space:]]*$//" \
    -e "/^$comment_char/d" \
    "$tmpfile" \
  | sed '/./,$!d' \
  | sed ':a;/^\n*$/{$d;N;ba;}'
  )"
```

But the following does not(replaced `^$comment_char` to `^$comment_char `)

```
  message="$(
  sed \
    -e "s/[[:space:]]*$//" \
    -e "/^$comment_char /d" \
    "$tmpfile" \
  | sed '/./,$!d' \
  | sed ':a;/^\n*$/{$d;N;ba;}'
  )"
```

I want to remove the lines that start with "#" and space, not those that start with "#" and other characters than space.
