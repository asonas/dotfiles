# git-ai-commit Codex Engine Design

## Goal

Configure git-ai-commit to generate commit messages through Codex using `gpt-5.6-terra`.

## Design

Store the git-ai-commit configuration in `.config/git-ai-commit/config.toml` and add that file to the paths managed by `install.sh`. The installer will symlink the tracked configuration to `~/.config/git-ai-commit/config.toml`, following the existing dotfiles installation pattern.

The configuration will select the `codex` engine and override its arguments with `codex exec --model gpt-5.6-terra --ephemeral -`. Terra provides an appropriate balance of quality and latency for short commit-message generation. Ephemeral execution avoids retaining a Codex session for each generated message.

## Validation

An installer test will verify that `install.sh` manages the new configuration path. A configuration test will verify the selected engine, model, and ephemeral execution argument. The existing test suite will continue to validate the rest of the dotfiles installation behavior.
