
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_DIR="$ROOT/shells"
PROJECT_DIR="$ROOT/projects"

mkdir -p "$PROJECT_DIR"

mapfile -t shells < <(
  find "$BASE_DIR" -maxdepth 1 -type f -name '*.nix' \
    -printf '%f\n' |
    sed 's/\.nix$//' |
    sort
)

if ((${#shells[@]} == 0)); then
  echo "No base shells found in $BASE_DIR" >&2
  exit 1
fi

echo "Available development shells:"
for i in "${!shells[@]}"; do
  printf '  %2d) %s\n' "$((i + 1))" "${shells[$i]}"
done

read -rp "Project shell name: " name

if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  echo "Invalid shell name." >&2
  exit 1
fi

output="$PROJECT_DIR/$name.nix"

if [[ -e "$output" ]]; then
  echo "Shell already exists: $output" >&2
  exit 1
fi

read -rp "Select shells (space-separated numbers): " selection

selected=()
for number in $selection; do
  if [[ ! "$number" =~ ^[0-9]+$ ]] ||
     ((number < 1 || number > ${#shells[@]})); then
    echo "Invalid selection: $number" >&2
    exit 1
  fi

  selected+=("${shells[$((number - 1))]}")
done

if ((${#selected[@]} == 0)); then
  echo "Select at least one shell." >&2
  exit 1
fi

{
  echo '{ pkgs, shells }:'
  echo
  echo 'pkgs.mkShell {'
  echo '  inputsFrom = ['

  for shell in "${selected[@]}"; do
    printf '    shells.%s\n' "$shell"
  done

  echo '  ];'
  echo '}'
} > "$output"

echo "Created $output"
echo "Remember to expose this project shell in flake.nix."
