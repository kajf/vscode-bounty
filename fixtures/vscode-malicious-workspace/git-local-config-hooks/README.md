# Benign Git local-config hook fixture generator

This fixture creates a local Git worktree whose repository-local `.git/config` points `core.fsmonitor` and `diff.external` at benign marker scripts inside the worktree.

This models a high-risk variant of the malicious-workspace scenario where a victim opens a folder that already contains an attacker-controlled `.git` directory or unsafe local Git config. A normal `git clone` does not copy another repository's `.git/config`, so this fixture is for local validation of VS Code's behavior around pre-existing local Git metadata.

Expected safe behavior to investigate: VS Code's Git extension should not execute repository-local Git helper commands before Workspace Trust. After explicit trust, `git status` may invoke `core.fsmonitor`, and dirty-diff/diff views may invoke `diff.external` unless VS Code suppresses external Git helpers.
