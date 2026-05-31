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

1. Open `fixtures/vscode-malicious-workspace/markdown-preview-links/sample.md` in Markdown Preview with clean user data.
2. Confirm script-like HTML does not set `data-inline-script-ran` or `data-inline-handler-ran` in the preview DOM under default security settings.
3. Confirm `command:` links do not execute internal VS Code commands and `vscode:` links do not perform privileged actions without explicit, understandable user mediation.
4. Record exact UI prompts and whether link targets are displayed/canonicalized safely.

## Debug preLaunchTask fixture expected result

1. Open `fixtures/vscode-malicious-workspace/launch-prelaunch-marker` with clean user data.
2. Confirm `debug-prelaunch-marker.txt` is absent before any debug configuration is started.
3. Start the `benign-node-with-prelaunch-marker` debug configuration deliberately.
4. Confirm VS Code requests Workspace Trust before running build/program code from the workspace.
5. Only after explicit trust and debug start, the marker may be created; that is expected debug/preLaunchTask behavior, not a vulnerability.

## Terminal link fixture expected result

1. Open `fixtures/vscode-malicious-workspace/terminal-link-samples` with clean user data.
2. Confirm no terminal output appears merely from opening the folder.
3. Run the `emit-benign-terminal-links` task manually.
4. Confirm link activation requires the normal terminal modifier or quick-pick selection.
5. Confirm `command:`-shaped output does not execute an internal VS Code command through the terminal URL opener, even though the fixture workspace settings add `command` to `terminal.integrated.allowedLinkSchemes`.
6. Confirm the custom `foo+bar:` URI either prompts for scheme approval or opens externally only after explicit approval.
7. Record how `vscode:`, `vscode-insiders:`, `file:`, and encoded `https:` targets are displayed and opened.

## Git local-config helper fixture expected result

1. Generate a throwaway fixture outside the repository, for example: `fixtures/vscode-malicious-workspace/git-local-config-hooks/create-fixture.sh /tmp/vscode-git-local-config-worktree`.
2. Confirm baseline Git behavior by running `git status --porcelain=v1`, `git diff -- tracked.txt`, and `git diff --no-ext-diff -- tracked.txt` inside the generated worktree and inspecting `git-local-config-marker.txt`.
3. Open the generated worktree in VS Code with clean user data and extensions.
4. Before granting Workspace Trust, confirm `git-local-config-marker.txt` is absent or unchanged.
5. After granting trust, observe whether Git repository discovery/status refresh appends `core.fsmonitor invoked`.
6. Open `tracked.txt` and/or a diff view to observe whether quick diff or explicit diff actions append `diff.external invoked`.
7. Repeat with `scm.diffDecorations: none` to separate passive editor decorations from explicit diff commands.

## Built-in task-provider autodetect fixture expected result

1. Open `fixtures/vscode-malicious-workspace/task-provider-autodetect` with clean user data and extensions.
2. Do not grant Workspace Trust and do not run the Tasks command.
3. Confirm `GULP_AUTODETECT_MARKER.txt` and `NPM_SCRIPT_MARKER.txt` are absent.
4. Run `Tasks: Run Task`; expected safe behavior is a Workspace Trust prompt before task listing can execute workspace code.
5. If the folder is trusted and application-scoped `gulp.autoDetect` is explicitly set to `on`, listing tasks may invoke the fake local gulp shim and create `GULP_AUTODETECT_MARKER.txt`; that is expected opt-in discovery behavior, not a reportable issue by itself.
6. Running the npm `build` task should require deliberate task selection and then create `NPM_SCRIPT_MARKER.txt` as expected task execution behavior.


## Protocol handler / extension URI fixture expected result

1. Open `fixtures/vscode-malicious-workspace/settings-restricted` with clean user data.
2. Confirm workspace-provided `extensions.confirmedUriHandlerExtensionIds` is ignored because it is application-scoped.
3. From a separate controlled source, test benign `vscode://vscode.git/clone?...` and extension-handler URI shapes only with non-sensitive local/test URLs.
4. Confirm extension URI handlers show the expected confirmation prompt unless the extension is trusted through profile/application state, not workspace settings.
5. Confirm Git clone protocol handling does not open/trust the cloned folder or run repository code without explicit user-mediated clone/open steps.


## Task/debug variable-resolution expected result

1. Extend or create a throwaway fixture with `${command:*}` and `inputs[].type: "command"` entries in `tasks.json` and `launch.json`, using only benign built-in commands.
2. Open with clean user data and do not grant Workspace Trust.
3. Confirm variable commands are not executed on folder open or passive configuration discovery.
4. Invoke task/debug flows deliberately and confirm VS Code requests Workspace Trust before resolving variables that could execute commands.
5. Confirm canceling any prompt aborts the task/debug launch rather than continuing with partial or attacker-chosen defaults.


## Built-in extension activation expected result

1. Open fixtures containing activation-trigger files such as `package.json` with clean user data and an initially untrusted workspace.
2. Confirm activation of limited-support built-ins such as npm does not execute repository scripts or local binaries merely from activation.
3. Confirm workspace-provided `extensions.supportUntrustedWorkspaces` is ignored because it is application-scoped.
4. After granting trust, observe which built-ins activate and ensure any command execution still requires explicit task/debug/user action.
