
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

echo "Available base shells:"
for i in "${!shells[@]}"; do
  printf '  %2d) %s\n' "$((i + 1))" "${shells[$i]}"
done

read -rp "Project shell name: " name

if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  echo "Invalid name. Use letters, numbers, underscores, or hyphens." >&2
  exit 1
fi

for shell in "${shells[@]}"; do
  if [[ "$name" == "$shell" ]]; then
    echo "Project name conflicts with base shell '$shell'." >&2
    exit 1
  fi
done

output="$PROJECT_DIR/$name.nix"

if [[ -e "$output" ]]; then
  echo "Project shell already exists: $output" >&2
  exit 1
fi

default_dir="$HOME/code/$name"
read -rp "Project directory for .envrc [$default_dir]: " project_dir
project_dir="${project_dir:-$default_dir}"

project_dir="${project_dir/#\~/$HOME}"
project_dir="$(realpath -m "$project_dir")"
envrc="$project_dir/.envrc"

if [[ -e "$envrc" ]]; then
  echo ".envrc already exists: $envrc" >&2
  echo "Refusing to overwrite it." >&2
  exit 1
fi

echo
echo "Select the shells to combine."
echo "Enter space-separated numbers, for example: 1 5 6 7"
read -rp "Selection: " selection

read -ra numbers <<< "$selection"

if ((${#numbers[@]} == 0)); then
  echo "Select at least one shell." >&2
  exit 1
fi

selected=()
declare -A seen=()

for number in "${numbers[@]}"; do
  if [[ ! "$number" =~ ^[0-9]+$ ]] ||
     ((10#$number < 1 || 10#$number > ${#shells[@]})); then
    echo "Invalid selection: $number" >&2
    exit 1
  fi

  shell="${shells[$((10#$number - 1))]}"

  if [[ -z "${seen[$shell]+yes}" ]]; then
    selected+=("$shell")
    seen["$shell"]=1
  fi
done

mkdir -p "$project_dir"

{
  printf '{ pkgs, shells }:\n\n'
  printf 'pkgs.mkShell {\n'
  printf '  inputsFrom = [\n'

  for shell in "${selected[@]}"; do
    printf '    shells.%s\n' "$shell"
  done

  printf '  ];\n'
  printf '}\n'
} > "$output"

{
  printf 'use flake "%s#%s"\n' "$ROOT" "$name"
} > "$envrc"

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT" add -N -- "projects/$name.nix"
fi

echo
echo "Created project shell: $output"
echo "Created direnv configuration: $envrc"
echo "Selected shells: ${selected[*]}"

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT" add -- "projects/$name.nix"

  if ! git -C "$ROOT" diff --cached --quiet -- "projects/$name.nix"; then
    git -C "$ROOT" commit -m "Add $name development shell"
  else
    echo "No staged changes to commit for projects/$name.nix"
  fi
else
  echo "Warning: $ROOT is not a Git repository; skipping commit." >&2
fi

echo
echo "Activate with:"
echo "  nix develop \"$ROOT#$name\""
echo
echo "In the project directory, run:"
echo "  direnv allow"