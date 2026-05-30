# Deep audit pass: malicious-workspace leads

Date: 2026-05-30
Upstream checkout: `microsoft/vscode` shallow clone at commit `f6d1fcfcfcb5225125221ff6fdd6ae8c699958d5`.

## Goal of this pass

This pass continued the malicious-repository-open audit beyond automatic tasks and restricted settings. It focused on code paths where repository content can influence command execution, URL opening, or local file writes after a user opens a folder.

No live Microsoft services were scanned or attacked. All new fixtures are benign and require local/manual activation.

## Lead 1: debug `launch.json`, `preLaunchTask`, and variable substitution

Primary files reviewed:

- `src/vs/workbench/contrib/debug/browser/debugService.ts`
- `src/vs/workbench/contrib/debug/common/debugger.ts`
- `src/vs/workbench/contrib/debug/browser/debugConfigurationManager.ts`
- `src/vs/workbench/services/configurationResolver/browser/baseConfigurationResolverService.ts`
- `src/vs/workbench/services/configurationResolver/common/configurationResolverSchema.ts`

Observed control flow:

1. `DebugService.startDebugging()` requests Workspace Trust before starting a debug session. The prompt text explicitly states that running/debugging executes build tasks and program code from the workspace.
2. Debug configuration lookup preserves the configuration target in `__configurationTarget`, distinguishing user, workspace, and workspace-folder launch configurations.
3. Debugger variable substitution calls `configurationResolverService.resolveWithInteractionReplace(..., 'launch', ..., substitutedConfig.__configurationTarget)` so `inputs` are resolved from the same configuration target rather than blindly mixing targets.
4. `${command:...}` variables and `inputs` of type `command` can execute registered VS Code commands during variable substitution, but this is reached only after the user starts debugging and passes the trust request.
5. `preLaunchTask` execution happens after variable substitution and before debug adapter startup. It uses the task runner path already covered by task trust/permission review.

Fixture added: `fixtures/vscode-malicious-workspace/launch-prelaunch-marker` writes a marker from a `preLaunchTask` only when the debug configuration is explicitly started.

Triage: no bypass found. A malicious `launch.json` remains an important social-engineering surface, but the reviewed path is user-mediated and Workspace Trust gated. A bounty-quality issue would need a path that starts debugging or resolves command inputs without the trust request or clear user action.

## Lead 2: task/debug command and input variables

Primary files reviewed:

- `src/vs/workbench/services/configurationResolver/browser/baseConfigurationResolverService.ts`
- `src/vs/workbench/contrib/tasks/browser/terminalTaskSystem.ts`
- `src/vs/workbench/contrib/debug/common/debugger.ts`

Observed control flow:

- The resolver treats `${command:id}` and `${input:id}` as interactive variables.
- For `${command:id}`, it calls `commandService.executeCommand(commandId, expr.toObject())` and requires a string result.
- For input definitions of type `command`, it calls `commandService.executeCommand(info.command, info.args)` and accepts a string or undefined result.
- Task execution collects command, args, cwd, env, shell executable/args, custom execution definitions, and problem matcher file prefixes for variable resolution.
- Task variable resolution passes `TaskSourceKind.toConfigurationTarget(task._source.kind)`, preserving workspace vs workspace-folder provenance for input lookup.

Triage: no standalone vulnerability found. Command/input variables are powerful and should stay in the audit set because they may amplify another bypass, but by themselves they require deliberate task/debug execution or automatic-task permission.

## Lead 3: terminal link activation and URL/file/command handling

Primary files reviewed:

- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalUriLinkDetector.ts`
- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalLinkManager.ts`
- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalLinkOpeners.ts`
- `src/vs/editor/browser/services/openerService.ts`

Observed control flow:

1. Terminal URI detection uses `LinkComputer.computeLinks` and treats non-`file:` schemes as URL links without filesystem resolution.
2. Terminal link activation requires the terminal link activation modifier unless the link was chosen from the link quick pick.
3. URL links are opened through `TerminalUrlLinkOpener`, which passes `openExternal: true` to the opener service.
4. Because `openExternal: true` is set, terminal URL links do not use the internal `CommandOpener` path that requires `allowCommands`; a `command:` string printed by terminal output should not execute as an internal command via this opener path.
5. `file:` links are special-cased: existing files/folders are delegated to local file/folder openers, while unresolved `file:` links fall back to external opening.

Fixture added: `fixtures/vscode-malicious-workspace/terminal-link-samples` prints benign `command:`, `vscode:`, `vscode-insiders:`, `file:`, and encoded `https:` shapes for local observation.

Triage: no bypass found in source review. Remaining runtime work is to confirm exact UI behavior for `command:` and `vscode:` terminal output in desktop VS Code and verify no internal command dispatch occurs.

## Lead 4: Markdown and editor command links

Primary files reviewed:

- `extensions/markdown-language-features/src/markdownEngine.ts`
- `extensions/markdown-language-features/src/preview/documentRenderer.ts`
- `extensions/markdown-language-features/preview-src/index.ts`
- `extensions/markdown-language-features/src/util/openDocumentLink.ts`
- `src/vs/editor/contrib/links/browser/links.ts`
- `src/vs/editor/browser/services/openerService.ts`

Observed control flow:

- Markdown preview renders raw HTML but wraps it in a webview with CSP. The default strict security level nonce-gates extension scripts and keeps `default-src 'none'`.
- Preview click handling delegates relative links back to the extension and lets selected known schemes behave as normal anchors. Extension-mediated opens resolve markdown links before calling `vscode.open` or `revealInExplorer`.
- Text editor link handling calls `openerService.open(..., { allowCommands: true, fromWorkspace: true })` for detected links, so command links in an opened source file are intentionally executable after the user uses the link activation gesture. The hover labels command links as command execution and omits full command arguments from native tooltip text.

Triage: no bypass found. Editor command links remain a UI/consent surface rather than passive execution. Future fuzzing should compare the displayed link target, markdown `data-href`, and actual opened URI for encoded or mixed-case scheme variants.

## Lead 5: `vscode://` protocol URL handlers

Primary files reviewed:

- `src/vs/workbench/services/url/browser/urlService.ts`
- `src/vs/workbench/services/url/electron-browser/urlService.ts`
- `src/vs/platform/url/common/urlService.ts`
- `src/vs/workbench/contrib/extensions/browser/extensionsWorkbenchService.ts`
- `src/vs/workbench/contrib/chat/browser/pluginUrlHandler.ts`
- `src/vs/workbench/contrib/chat/browser/promptSyntax/promptUrlHandler.ts`
- `src/vs/workbench/contrib/chat/browser/chatSetup/chatSetupContributions.ts`

Observed control flow:

- Internal URL services dispatch product-protocol URLs to registered URL handlers.
- Extension detail URLs under `/extension/<id>` open extension details; this is not command execution by itself.
- Plugin marketplace install/add-marketplace URL handlers show confirmation dialogs before installing plugins or adding marketplaces.
- Prompt/instructions/agent install URL handlers confirm with the user before fetching URL content, then ask for a destination folder and file name before writing a file.
- Chat setup URLs can open chat with a supplied prompt or agent/mode parameter. This is potentially relevant to prompt-injection research, but it is not a local-code-execution primitive by itself.

Triage: no bounty-quality issue found. The highest-value future work is canonicalization testing for protocol URLs reached from markdown/webviews/terminal links, especially whether the string shown to the user matches the handler action.

## Lead 6: MCP workspace-defined servers and automatic starts

Primary files reviewed:

- `src/vs/workbench/contrib/mcp/common/mcpRegistry.ts`
- `src/vs/workbench/contrib/mcp/common/mcpGatewayToolBrokerChannel.ts`
- `src/vs/workbench/contrib/mcp/common/discovery/extensionMcpDiscovery.ts`
- `src/vs/workbench/contrib/mcp/common/discovery/nativeMcpDiscoveryAbstract.ts`

Observed control flow:

- `McpRegistry._checkTrust()` first blocks workspace-scoped definitions when the workspace is untrusted, either by requesting Workspace Trust or throwing `UserInteractionRequiredError` when interaction is not allowed.
- `TrustedOnNonce` definitions compare the current definition nonce to the last trusted nonce. Unknown or changed definitions are prompted unless the caller explicitly used `autoTrustChanges` for a user-executed flow.
- Automatic/non-interactive broker paths call start helpers with `errorOnUserInteraction: true`, so missing workspace trust, server trust, or variable input should fail closed rather than prompt unexpectedly.
- Variable replacement for MCP launches checks for unresolved variables and throws `UserInteractionRequiredError('variables')` when non-interactive startup would require input.

Triage: no bypass found in this pass. MCP remains high priority because workspace-defined servers can launch local commands after trust, and because `autoTrustChanges` call sites need complete enumeration.

## Current finding status

No validated, reproducible, in-scope vulnerability was found in this deeper pass. The best current leads are not report-ready because they either require explicit user execution, Workspace Trust, automatic-task permission, or a confirmation dialog. No MSRC report should be submitted from these notes alone.

## Next focused experiments

1. Build or run a released VS Code locally with clean user data and execute the marker fixtures in this order: automatic task, restricted settings, debug prelaunch, terminal links, markdown links.
2. Instrument or log whether `command:` terminal output reaches `CommandOpener`; expected result is no because terminal URL links use `openExternal: true`.
3. Fuzz markdown/editor/protocol URL canonicalization: mixed-case schemes, leading whitespace/control characters, encoded colon, HTML entities, punycode/IDNA, nested markdown/HTML links, and fragments/query strings.
4. Enumerate MCP `autoTrustChanges` call sites and confirm each one is only reachable from a deliberate user action.
5. Continue with Git clone/open-folder and built-in extension activation boundaries after the above runtime checks.
