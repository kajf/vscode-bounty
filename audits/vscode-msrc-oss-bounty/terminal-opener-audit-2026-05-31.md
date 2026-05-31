# Terminal and opener command-URI audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: repository-controlled terminal output and URI opener routing

This pass reviewed whether a malicious workspace can print or configure link-shaped terminal output that reaches VS Code's internal `command:` opener, or otherwise bypasses expected user activation and scheme mediation.

Primary files reviewed:

- `src/vs/editor/browser/services/openerService.ts`
- `src/vs/editor/contrib/links/browser/links.ts`
- `src/vs/editor/common/languages/linkComputer.ts`
- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalLinkManager.ts`
- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalUriLinkDetector.ts`
- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalWordLinkDetector.ts`
- `src/vs/workbench/contrib/terminalContrib/links/browser/terminalLinkOpeners.ts`
- `src/vs/workbench/contrib/terminal/common/terminalConfiguration.ts`

## Source observations

- `CommandOpener` executes `command:` URIs only when `OpenOptions.allowCommands` is set. If `allowCommands` is absent, command links are silently consumed and not executed.
- Editor text links are different from terminal links: the editor link contribution calls `openerService.open(..., { allowCommands: true, fromWorkspace: true })` after an explicit editor link activation gesture. This can execute `command:` links, but it requires the victim to deliberately click a command-shaped link in a file.
- `LinkComputer`'s built-in scanner recognizes `http://`, `https://`, and `file://` schemes, not arbitrary `command:` text, for normal editor/terminal URI detection.
- The terminal link manager requires the terminal link activation modifier before opening xterm-detected links. For non-default schemes, it prompts before adding the scheme to `terminal.integrated.allowedLinkSchemes`.
- `terminal.integrated.allowedLinkSchemes` defaults to `file`, `http`, `https`, `mailto`, `vscode`, and `vscode-insiders`; it is not marked restricted in the terminal configuration schema, so a workspace can attempt to broaden the allowed set.
- Terminal URL openers pass URL text to `openerService.open()` with `openExternal: true` and do not pass `allowCommands`. Because `openExternal` is handled before `CommandOpener`, terminal `command:` output should route to the external opener path rather than execute an internal VS Code command.
- File-scheme terminal links are routed through local file/folder openers after file-service checks, while non-file schemes are treated as URL links.

## Fixture update

Updated `fixtures/vscode-malicious-workspace/terminal-link-samples/` so the manual task prints two `command:` URI shapes plus `vscode:`, `vscode-insiders:`, `file:`, `https:`, and a custom `foo+bar:` URI. The fixture now also includes workspace settings that add `command` and `foo+bar` to `terminal.integrated.allowedLinkSchemes` to model a malicious repository broadening terminal link schemes.

Expected safe runtime behavior: merely opening the folder must not run the task. After the user manually runs the task, terminal link activation must require the normal gesture. Even with workspace-expanded allowed schemes, `command:` terminal output should not execute an internal VS Code command because the terminal URL opener uses `openExternal: true` and does not set `allowCommands`.

## Triage

Current status: **no terminal command-URI execution bypass found in source review**.

This lead is not report-ready unless runtime validation shows terminal output can execute an internal command without a clear user gesture, can bypass the allowed-scheme prompt, or reaches `CommandOpener` despite the terminal opener's `openExternal: true` routing. The workspace-configurable `allowedLinkSchemes` setting may be worth hardening discussion, but by itself it does not appear to create internal command execution from terminal output.
