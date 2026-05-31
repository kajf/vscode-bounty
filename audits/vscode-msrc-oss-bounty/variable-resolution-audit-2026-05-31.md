# Task/debug variable-resolution audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: `${command:*}` and `${input:*}` variables in task/debug configuration

This pass reviewed whether repository-controlled `.vscode/tasks.json` or `.vscode/launch.json` variables can execute commands or prompt for misleading input before Workspace Trust or without deliberate task/debug user action.

Primary files reviewed:

- `src/vs/workbench/services/configurationResolver/browser/baseConfigurationResolverService.ts`
- `src/vs/workbench/services/configurationResolver/common/configurationResolver.ts`
- `src/vs/workbench/services/configurationResolver/common/configurationResolverSchema.ts`
- `src/vs/workbench/services/configurationResolver/common/variableResolver.ts`
- `src/vs/workbench/contrib/tasks/browser/abstractTaskService.ts`
- `src/vs/workbench/contrib/tasks/browser/terminalTaskSystem.ts`
- `src/vs/workbench/contrib/debug/browser/debugService.ts`
- `src/vs/workbench/contrib/debug/common/debugger.ts`

## Source observations

- `BaseConfigurationResolverService.resolveWithInteraction()` executes `${command:name}` by calling `commandService.executeCommand(commandId, expr.toObject())` and requires a string result for substitution.
- `${input:id}` supports `promptString`, `pickString`, and `command` input types. `promptString`/`pickString` are user-visible quick-input flows; `input` of type `command` calls `commandService.executeCommand(info.command, info.args)` and also requires a string or undefined result.
- Input prompts are serialized through `userInputAccessQueue`, and canceled input aborts the whole resolution flow by returning `undefined`.
- Task listing/running paths call the central task-service `_trust()` helper. In untrusted workspaces, `_trust()` requests Workspace Trust with an explicit message that listing/running tasks may execute workspace files as code.
- Debug startup calls `requestWorkspaceTrust()` before activating debug providers, resolving variables, running `preLaunchTask`, or launching program code. The trust prompt explicitly says running/debugging executes build tasks and workspace program code.
- Debug variable substitution uses `resolveWithInteractionReplace(..., 'launch', ...)` after debug trust is requested. Task execution reaches `TerminalTaskSystem` through `AbstractTaskService.run()` and the task-service trust gate.
- No source-reviewed path was found where repository-defined command/input variables are resolved automatically on folder open before Workspace Trust. The remaining risk is indirect callers that resolve workspace task/debug configuration outside the normal task/debug trust gates.

## Triage

Current status: **no pre-trust variable-command execution bypass found in source review**.

This lead is not report-ready unless runtime validation shows `${command:*}` or `inputs[].type: "command"` from repository configuration can execute before Workspace Trust, without explicit task/debug invocation, or through a misleading UI path that hides the command source and security implication.
