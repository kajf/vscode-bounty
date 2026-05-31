# Built-in task-provider trust audit pass

Date: 2026-05-30
Upstream checkout: `microsoft/vscode` shallow clone at commit `7eff9ee6bd6f4bd34c0cbe46837156d452d8a614`.

## Lead: built-in task providers that discover tasks from repository content

This pass checked whether default/built-in task providers can execute repository-controlled code while merely opening or listing tasks in an untrusted malicious workspace.

Primary files reviewed:

- `extensions/npm/src/npmMain.ts`
- `extensions/npm/src/tasks.ts`
- `extensions/npm/src/scriptHover.ts`
- `extensions/gulp/src/main.ts`
- `extensions/grunt/src/main.ts`
- `extensions/jake/src/main.ts`
- `src/vs/workbench/contrib/tasks/browser/abstractTaskService.ts`
- `src/vs/workbench/contrib/tasks/browser/runAutomaticTasks.ts`
- `src/vs/workbench/contrib/tasks/browser/task.contribution.ts`

## Source observations

- The `npm` extension activates for `workspaceContains:package.json` and supports untrusted workspaces in limited mode, but `getNPMCommandPath()` only resolves the `npm` executable when `vscode.workspace.isTrusted` is true.
- `npm` task discovery reads `package.json` files and constructs `ShellExecution` task objects for scripts/install tasks. It does not execute the package-manager command during discovery; actual execution goes through `tasks.executeTask()`.
- NPM hover and tree-view actions create trusted command links/buttons that run scripts, but those paths require an explicit click/command and still call the task service for execution.
- The `gulp`, `grunt`, and `jake` task providers are marked supported in untrusted workspaces, but their auto-detection settings are application-scoped and default to `off`.
- When enabled and asked to provide tasks, the gulp/grunt/jake providers execute local or global task-listing commands such as `./node_modules/.bin/gulp --tasks-simple --no-color`, `grunt --help --no-color`, or `jake --tasks` from the workspace folder.
- The central task service calls `_trust()` before user-facing task listing/running paths such as `getTask()`, `tryResolveTask()`, `run()`, and `getWorkspaceTasks()`. The trust prompt says listing and running tasks may execute workspace files as code.
- Automatic folder-open tasks are separately blocked when Workspace Trust is absent, and the `task.allowAutomaticTasks` setting description states automatic tasks do not run in untrusted workspaces.

## Local fixture

Added `fixtures/vscode-malicious-workspace/task-provider-autodetect/` with:

- a minimal `package.json` containing a benign `build` script,
- a `gulpfile.js`, and
- a fake executable `node_modules/.bin/gulp` shim that writes `GULP_AUTODETECT_MARKER.txt` when invoked.

Expected safe runtime behavior: opening the fixture in a clean, initially untrusted VS Code profile must not create `GULP_AUTODETECT_MARKER.txt` or `NPM_SCRIPT_MARKER.txt`. If the user later trusts the folder, enables application-scoped `gulp.autoDetect`, and lists tasks, the gulp marker may be created as expected task-discovery behavior.

## Triage

Current status: **no default untrusted-workspace execution bypass found in source review**.

This lead remains worth a clean-profile runtime test because gulp/grunt/jake discovery does execute local commands when enabled. It is not report-ready unless a default path reaches provider execution before Workspace Trust, before the task-listing trust prompt, or without a user/application-level opt-in for the providers whose detection executes code.
