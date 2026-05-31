# Runtime validation pass: clean-profile open-only fixtures

Date: 2026-05-31
Runtime target: Visual Studio Code Stable `1.122.1` (`8761a5560cfd65fdd19ce7e2bd18dab5c0a4d84e`, x64) installed from the official Linux `.deb` update endpoint.
Environment: Ubuntu 24.04 container, root user, Xvfb display, local fixtures only.

## Goal

Validate the highest-priority passive-open leads from the malicious-workspace audit against a real VS Code runtime before spending more time on deeper UI automation. This pass intentionally avoided live-service testing and did not click trust prompts, task prompts, markdown links, protocol prompts, or debug controls. The question was whether merely opening attacker-controlled local folders with a fresh profile caused marker-based command execution.

## Harness

For each folder, I created a fresh `--user-data-dir` and `--extensions-dir`, copied a user settings file that disabled telemetry/update/experiment features where possible, and launched VS Code under `xvfb-run` with `--no-sandbox`, `--disable-gpu`, `--disable-telemetry`, `--skip-welcome`, `--new-window`, and `--wait`. Each launch was bounded by `timeout`; exit code `124` was expected because VS Code remains open until the timeout kills the window. The reusable harness is checked in as `fixtures/vscode-malicious-workspace/run-clean-profile-open-checks.sh`.

The local-only folders opened in this pass were:

1. `fixtures/vscode-malicious-workspace/tasks-autorun-marker`
2. `fixtures/vscode-malicious-workspace/tasks-manual-marker`
3. `fixtures/vscode-malicious-workspace/launch-prelaunch-marker`
4. `fixtures/vscode-malicious-workspace/task-provider-autodetect`
5. A generated Git worktree from `fixtures/vscode-malicious-workspace/git-local-config-hooks/create-fixture.sh`
6. `fixtures/vscode-malicious-workspace/settings-restricted`

## Runtime results

| Lead | Marker checked | Result |
|---|---|---|
| Automatic `runOn: folderOpen` task | `fixtures/vscode-malicious-workspace/tasks-autorun-marker/autorun-task-marker.txt` | Absent after clean-profile open |
| Manual workspace task | `fixtures/vscode-malicious-workspace/tasks-manual-marker/manual-task-marker.txt` | Absent after clean-profile open |
| Debug `preLaunchTask` fixture | `fixtures/vscode-malicious-workspace/launch-prelaunch-marker/debug-prelaunch-marker.txt` | Absent after clean-profile open |
| Built-in npm/gulp task-provider autodetect | `fixtures/vscode-malicious-workspace/task-provider-autodetect/GULP_AUTODETECT_MARKER.txt` and `NPM_SCRIPT_MARKER.txt` | Absent after clean-profile open |
| Git local-config helper fixture | `/tmp/vscode-git-local-config-runtime/git-local-config-marker.txt` | Absent after clean-profile open |
| Restricted workspace settings fixture | Marker-free observation fixture | Opened without marker-based execution to check; no reportable behavior observed in this open-only pass |

No passive-open runtime bypass was reproduced in this pass. These results reduce the likelihood of an immediate MSRC-quality issue in the automatic-task, debug-prelaunch, built-in task-provider autodetect, and Git local-config helper leads, but they do not fully close the areas because this harness did not automate trust acceptance, UI commands, markdown preview interactions, terminal link clicks, or debug start actions.

## Git helper control check

The generated Git fixture still demonstrates why this lead remains worth tracking: direct local Git commands can invoke repository-local helper settings. In the control run, `git status --porcelain=v1` appended `core.fsmonitor invoked`, `git diff -- tracked.txt` appended both `core.fsmonitor invoked` and `diff.external invoked`, and `git --no-pager diff --no-ext-diff -- tracked.txt` still appended `core.fsmonitor invoked`. VS Code's passive-open run did not append the marker, so the current runtime evidence is negative for passive-open exploitation.

## Current triage impact

- **Candidate A: automatic folder-open tasks** moves from pending runtime validation to negative for clean-profile passive open. Continue only if testing trust/allow persistence, policy bypasses, or UI-confusion angles.
- **Candidate D: restricted workspace settings** remains negative at source level and produced no marker-based runtime signal in this open-only pass.
- **Candidate I: Git local-config helpers** remains interesting as a Git behavior, but the clean-profile VS Code open did not trigger the helper marker. The next useful check is interactive/automated SCM actions after explicit trust, especially diff decorations, source-control view expansion, and file diff opening.
- **Candidate J: built-in task-provider autodetect** moves to negative for passive open because fake gulp/npm marker scripts were not executed.
- **Candidate E: debug `preLaunchTask`** remains expected user-mediated execution; passive opening did not run the prelaunch marker.

## Remaining runtime work

1. Automate VS Code UI actions in a local-only environment: accept workspace trust, open the Source Control view, open a file diff, run task-detection commands, start the debug config, open markdown preview, and click terminal/markdown links.
2. Compare trusted vs untrusted workspaces with identical fixtures and isolated profiles.
3. Expand logs collected from `--log trace` runs if a marker appears during any interactive path.
4. Do not prepare an MSRC report unless a marker-producing path becomes reproducible without expected user-mediated consent or demonstrates a meaningful trust/policy bypass.
