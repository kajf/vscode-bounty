#!/usr/bin/env bash
set -euo pipefail

# Open each malicious-workspace fixture in VS Code with a clean profile and
# report whether any benign command-execution marker was created. The command is
# intentionally open-only: it does not click trust prompts, run tasks, start
# debug configurations, or activate links.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES="$ROOT/fixtures/vscode-malicious-workspace"
RUNTIME_DIR="${RUNTIME_DIR:-$ROOT/.runtime-validation/$(date -u +%Y%m%dT%H%M%SZ)}"
CODE_BIN="${CODE_BIN:-code}"
OPEN_TIMEOUT_SECONDS="${OPEN_TIMEOUT_SECONDS:-20}"

command -v "$CODE_BIN" >/dev/null
command -v xvfb-run >/dev/null

mkdir -p "$RUNTIME_DIR/logs"
cat > "$RUNTIME_DIR/settings.json" <<'JSON'
{
  "telemetry.telemetryLevel": "off",
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false,
  "update.mode": "none",
  "workbench.enableExperiments": false,
  "workbench.startupEditor": "none",
  "security.workspace.trust.startupPrompt": "always"
}
JSON

run_open() {
  local name="$1"
  local folder="$2"
  local seconds="${3:-$OPEN_TIMEOUT_SECONDS}"
  local user="$RUNTIME_DIR/$name-user-data"
  local ext="$RUNTIME_DIR/$name-extensions"

  rm -rf "$user" "$ext"
  mkdir -p "$user/User" "$ext"
  cp "$RUNTIME_DIR/settings.json" "$user/User/settings.json"

  printf '=== %s ===\nfolder=%s\n' "$name" "$folder"
  set +e
  timeout "${seconds}s" xvfb-run -a "$CODE_BIN" \
    --no-sandbox \
    --disable-gpu \
    --disable-telemetry \
    --user-data-dir "$user" \
    --extensions-dir "$ext" \
    --skip-welcome \
    --new-window \
    --wait \
    "$folder" >"$RUNTIME_DIR/logs/$name.stdout" 2>"$RUNTIME_DIR/logs/$name.stderr"
  local rc=$?
  set -e
  printf 'exit=%s\n' "$rc"

  # Kill any window left behind by the bounded open-only run.
  pkill -f "$user" >/dev/null 2>&1 || true
  sleep 1
}

rm -f "$FIXTURES/tasks-autorun-marker/autorun-task-marker.txt"
rm -f "$FIXTURES/tasks-manual-marker/manual-task-marker.txt"
rm -f "$FIXTURES/launch-prelaunch-marker/debug-prelaunch-marker.txt"
rm -f "$FIXTURES/task-provider-autodetect/GULP_AUTODETECT_MARKER.txt"
rm -f "$FIXTURES/task-provider-autodetect/NPM_SCRIPT_MARKER.txt"

run_open tasks-autorun "$FIXTURES/tasks-autorun-marker"
run_open tasks-manual "$FIXTURES/tasks-manual-marker"
run_open launch-prelaunch "$FIXTURES/launch-prelaunch-marker"
run_open task-provider-autodetect "$FIXTURES/task-provider-autodetect" 25

rm -rf /tmp/vscode-git-local-config-runtime
bash "$FIXTURES/git-local-config-hooks/create-fixture.sh" /tmp/vscode-git-local-config-runtime >"$RUNTIME_DIR/logs/git-fixture-create.stdout" 2>"$RUNTIME_DIR/logs/git-fixture-create.stderr"
rm -f /tmp/vscode-git-local-config-runtime/git-local-config-marker.txt
run_open git-local-config /tmp/vscode-git-local-config-runtime 25

run_open settings-restricted "$FIXTURES/settings-restricted"

printf '\nMARKERS\n'
markers=(
  "$FIXTURES/tasks-autorun-marker/autorun-task-marker.txt"
  "$FIXTURES/tasks-manual-marker/manual-task-marker.txt"
  "$FIXTURES/launch-prelaunch-marker/debug-prelaunch-marker.txt"
  "$FIXTURES/task-provider-autodetect/GULP_AUTODETECT_MARKER.txt"
  "$FIXTURES/task-provider-autodetect/NPM_SCRIPT_MARKER.txt"
  "/tmp/vscode-git-local-config-runtime/git-local-config-marker.txt"
)
for marker in "${markers[@]}"; do
  if [[ -e "$marker" ]]; then
    printf 'PRESENT %s\n' "$marker"
    cat "$marker"
  else
    printf 'ABSENT %s\n' "$marker"
  fi
done

printf '\nLogs: %s/logs\n' "$RUNTIME_DIR"
