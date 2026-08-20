#!/bin/bash
set -e

cd "$(dirname "$0")"

"$PWD/bin/ensure_main_worktree"

"$PWD/bin/link_legacy_dotfiles" "$PWD" "$HOME"

# Apply entries that have already migrated to chezmoi. The legacy link loop
# remains in place while the source state is migrated incrementally; machines
# without chezmoi keep the existing behavior.
if command -v chezmoi >/dev/null 2>&1; then
    echo "==> chezmoi apply (migrated dotfiles)"
    "$PWD/bin/apply_chezmoi_dotfiles"
fi

"$PWD/bin/install_gpg_agent_config" \
    "$PWD/.gnupg/gpg-agent.conf" \
    "$HOME/.gnupg/gpg-agent.conf"

"$PWD/bin/install_platform_links"

"$PWD/bin/install_apm_environment"

"$PWD/bin/install_local_skills"

"$PWD/bin/install_external_tools"
