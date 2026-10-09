#!/bin/zsh

while true; do
  printf '\nDrag file to here.\n'
  printf '> '

  IFS= read -r file

  [[ -z "$file" ]] && continue

  # Remove surrounding quotes
  file="${file#\'}"
  file="${file%\'}"
  file="${file#\"}"
  file="${file%\"}"

  if [[ -f "$file" ]]; then
    cp "$file" .
    printf '\nCopied: %s\n' "${file:t}"
    break
  else
    printf '\nFile no existed:\n%s\n' "$file"
  fi
done

printf '\nPress any key to close...'
read -k 1
