#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'command rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/repo" "$tmp_dir/home"
"$repo_root/bin/link_legacy_dotfiles" "$tmp_dir/repo" "$tmp_dir/home"

[ "$(readlink "$tmp_dir/home/.gitconfig")" = "$tmp_dir/repo/.gitconfig" ]
[ "$(readlink "$tmp_dir/home/.config/starship.toml")" = "$tmp_dir/repo/.config/starship.toml" ]
