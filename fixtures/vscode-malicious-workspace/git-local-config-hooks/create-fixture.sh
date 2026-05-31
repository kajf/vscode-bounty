#!/usr/bin/env bash
set -euo pipefail

out_dir="${1:-$(pwd)/worktree}"
rm -rf "$out_dir"
mkdir -p "$out_dir"
cd "$out_dir"

git init -q
git config user.email fixture@example.invalid
git config user.name 'VS Code Fixture'
printf 'original\n' > tracked.txt
git add tracked.txt
git commit -qm init
printf 'modified\n' > tracked.txt

cat > .vscode-git-fsmonitor-marker.sh <<'SH'
#!/bin/sh
printf 'core.fsmonitor invoked\n' >> git-local-config-marker.txt
# Intentionally return an empty token; this is enough to show invocation without doing useful work.
exit 0
SH
chmod +x .vscode-git-fsmonitor-marker.sh

cat > .vscode-git-diff-external-marker.sh <<'SH'
#!/bin/sh
printf 'diff.external invoked\n' >> git-local-config-marker.txt
exit 0
SH
chmod +x .vscode-git-diff-external-marker.sh

git config core.fsmonitor ./.vscode-git-fsmonitor-marker.sh
git config diff.external ./.vscode-git-diff-external-marker.sh

cat <<MSG
Created benign Git local-config fixture at: $out_dir

Local command checks:
  (cd "$out_dir" && git status --porcelain=v1)
  (cd "$out_dir" && git diff -- tracked.txt)
  (cd "$out_dir" && git --no-pager diff --no-ext-diff -- tracked.txt)

Open the worktree in VS Code with a clean profile to observe whether/when marker lines are appended to:
  $out_dir/git-local-config-marker.txt
MSG
