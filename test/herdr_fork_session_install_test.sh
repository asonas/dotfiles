#!/bin/bash
set -eu

repo_root=$(cd "$(dirname "$0")/.." && pwd)
install_script="$repo_root/install.sh"

assert_bin_linked() {
    command_name="$1"
    expected="ln -sf \"\$PWD/bin/$command_name\" \"\$HOME/bin/$command_name\""
    count=$(grep -Fxc "$expected" "$install_script" || true)

    if [ "$count" -ne 1 ]; then
        echo "expected install.sh to link $command_name into \$HOME/bin" >&2
        exit 1
    fi
}

assert_bin_linked herdr-fork-claude-session
assert_bin_linked herdr-fork-codex-session
assert_bin_linked hw

for config in "$repo_root/.config/herdr/config.macos.toml" "$repo_root/.config/herdr/config.linux.toml"
do
    grep -Fxc '[ui.toast]' "$config" | grep -Fx 1 >/dev/null
    grep -Fxc 'delivery = "herdr"' "$config" | grep -Fx 1 >/dev/null
done
