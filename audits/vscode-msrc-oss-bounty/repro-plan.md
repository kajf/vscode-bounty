# Local reproduction plan for future passes

This file intentionally avoids exploit payloads. It documents safe local validation steps for benign marker-based fixtures.

## Common VS Code launch isolation

Use a fresh user-data directory and extensions directory so prior trust and automatic-task decisions do not contaminate results:

```bash
mkdir -p .cache/vscode-user-data .cache/vscode-extensions
# From a built VS Code checkout, adapt the executable path as appropriate.
./scripts/code.sh \
  --user-data-dir "$PWD/.cache/vscode-user-data" \
  --extensions-dir "$PWD/.cache/vscode-extensions" \
  "$PWD/fixtures/vscode-malicious-workspace/tasks-autorun-marker"
```

## Automatic task fixture expected result

1. Open `fixtures/vscode-malicious-workspace/tasks-autorun-marker` with clean user data.
2. Do not click any trust or task-allow prompt.
3. Check that `autorun-task-marker.txt` is absent.
4. If VS Code prompts to allow automatic tasks, deny or close the prompt and confirm the marker remains absent.
5. Only after explicit allow/trust, the marker may be created; that is expected feature behavior, not a vulnerability.

## Manual task fixture expected result

1. Open `fixtures/vscode-malicious-workspace/tasks-manual-marker` with clean user data.
2. Confirm `manual-task-marker.txt` is absent before any task is manually selected.
3. Run the visible task intentionally.
4. Confirm `manual-task-marker.txt` is created only after that deliberate action.

## Restricted workspace-settings fixture expected result

1. Open `fixtures/vscode-malicious-workspace/settings-restricted` with clean user data.
2. Confirm VS Code does not treat workspace-provided `security.workspace.trust.enabled: false` as disabling Workspace Trust.
3. Confirm workspace-provided `task.allowAutomaticTasks: on` does not globally allow automatic tasks.
4. Confirm workspace-provided `extensions.supportUntrustedWorkspaces` does not alter built-in trust boundaries from repository scope.
5. Record any settings UI warnings that indicate application-scoped or restricted settings are ignored at workspace scope.

## Markdown fixture expected result

1. Open markdown samples in preview with clean user data.
2. Confirm script-like HTML does not execute.
3. Confirm `command:` or `vscode:` links do not perform privileged actions without explicit, understandable user mediation.
4. Record exact UI prompts and whether link targets are displayed/canonicalized safely.
