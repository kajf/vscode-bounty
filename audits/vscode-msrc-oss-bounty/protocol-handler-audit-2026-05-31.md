# Protocol handler and extension URI audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: `vscode://` / extension URI handlers reachable from repository content

This pass reviewed built-in URL routing and default extension URI handlers that a malicious repository might try to trigger through Markdown, terminal output, or editor links.

Primary files reviewed:

- `src/vs/platform/url/common/urlService.ts`
- `src/vs/workbench/services/extensions/browser/extensionUrlHandler.ts`
- `src/vs/workbench/contrib/extensions/browser/extensions.contribution.ts`
- `extensions/git/src/protocolHandler.ts`
- `src/vs/workbench/contrib/mcp/browser/mcpWorkbenchService.ts`

## Source observations

- The platform URL service fans incoming URIs out to registered handlers and stops on the first handler that returns true.
- Generic extension URI handling only accepts authorities that look like extension IDs. If the handler is not already trusted through product configuration, profile storage, or `extensions.confirmedUriHandlerExtensionIds`, the user is prompted before the extension opens the URI.
- `extensions.confirmedUriHandlerExtensionIds` is registered with `ConfigurationScope.APPLICATION`, so repository workspace settings should not be able to silently pre-authorize extension URI handlers.
- If an extension URI targets an uninstalled extension, the URL handler routes through `workbench.extensions.installExtension` with an explicit justification; this is user-mediated and outside a default malicious-workspace auto-execution path.
- The built-in Git URI handler supports `/clone` and validates clone URL schemes. On non-Windows platforms it accepts `file`, `git`, `http`, `https`, and `ssh`; on Windows it excludes `file`. It also validates `ref` against a denylist before invoking `git.clone`.
- Git URI handling does not itself run repository code; the risky follow-up remains the already-tracked clone/open/trust transition and Git local-config helper surface.
- MCP URL handling accepts `mcp/install`, `mcp/by-name/*`, and `mcp/*`. Gallery lookups are routed through the MCP gallery service, and `mcp/install` opens an install UI for local/remote server configuration rather than directly starting a workspace-defined server.
- The MCP handler comments explicitly avoid outbound requests to arbitrary gallery URLs supplied in the protocol payload by verifying gallery servers by name against the active gallery.

## Fixture update

Updated `fixtures/vscode-malicious-workspace/settings-restricted/.vscode/settings.json` to attempt setting `extensions.confirmedUriHandlerExtensionIds` from workspace scope. Expected safe behavior: opening the fixture must not suppress extension URI handler prompts for built-in or installed extensions because the setting is application-scoped.

## Triage

Current status: **no protocol-handler auto-execution bypass found in source review**.

This lead is not report-ready unless runtime validation shows repository-controlled content can trigger a `vscode://` handler without a clear user gesture, suppress extension URI confirmation from workspace scope, install/activate an extension without user mediation, or transition from Git/MCP protocol handling into local command execution before the normal Workspace Trust and server/task trust gates.
