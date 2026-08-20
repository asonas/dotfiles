#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"
ln -s "$repo_root/test/fixtures/fake_chezmoi" "$tmp_dir/bin/chezmoi"

args_file="$tmp_dir/args"
PATH="$tmp_dir/bin:$PATH" CHEZMOI_ARGS_FILE="$args_file" \
    "$repo_root/bin/apply_chezmoi_dotfiles"

expected=$(printf '%s\n%s\n%s' \
    '--source' \
    "$repo_root/chezmoi" \
    'apply')
actual=$(<"$args_file")

if [ "$actual" != "$expected" ]; then
    printf 'unexpected chezmoi arguments:\n%s\n' "$actual" >&2
    exit 1
fi

[ -f "$repo_root/chezmoi/dot_config/starship.toml" ]
[ -L "$repo_root/.config/starship.toml" ]
[ "$(readlink "$repo_root/.config/starship.toml")" = '../chezmoi/dot_config/starship.toml' ]
[ -f "$repo_root/chezmoi/dot_gemrc" ]
[ -L "$repo_root/.gemrc" ]
[ "$(readlink "$repo_root/.gemrc")" = 'chezmoi/dot_gemrc' ]
[ -f "$repo_root/chezmoi/dot_config/peco/config.json" ]
[ -L "$repo_root/.config/peco" ]
[ "$(readlink "$repo_root/.config/peco")" = '../chezmoi/dot_config/peco' ]
[ -f "$repo_root/chezmoi/dot_psqlrc" ]
[ -L "$repo_root/.psqlrc" ]
[ "$(readlink "$repo_root/.psqlrc")" = 'chezmoi/dot_psqlrc' ]
