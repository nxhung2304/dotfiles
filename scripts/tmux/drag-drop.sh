#!/bin/zsh

while true; do
  printf '\nDrag files or folders to here.\n'
  printf '> '

  IFS= read -r input

  [[ -z "$input" ]] && continue

  dropped_paths=(${(Q)${(z)input}})
  copied_count=0

  for dropped_path in "${dropped_paths[@]}"; do
    dropped_path="${dropped_path%/}"

    if [[ -e "$dropped_path" ]] && cp -R "$dropped_path" .; then
      printf '\nCopied: %s\n' "${dropped_path:t}"
      copied_count=$((copied_count + 1))
    else
      printf '\nNot found or copy failed:\n%s\n' "$dropped_path"
    fi
  done

  (( copied_count > 0 )) && break
done

printf '\nPress any key to close...'
read -k 1
