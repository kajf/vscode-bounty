# MCP trust/autostart audit pass

Date: 2026-05-30
Upstream checkout: `microsoft/vscode` shallow clone at commit `f6d1fcfcfcb5225125221ff6fdd6ae8c699958d5`.

## Lead: MCP server trust, autostart, and `autoTrustChanges`

This pass enumerated MCP server start paths because workspace-defined MCP servers can launch local commands after trust. The focus was whether any automatic path can bypass Workspace Trust, server trust, nonce changes, or variable-input prompts.

Primary files reviewed:

- `src/vs/workbench/contrib/mcp/common/mcpRegistry.ts`
- `src/vs/workbench/contrib/mcp/common/mcpServer.ts`
- `src/vs/workbench/contrib/mcp/common/mcpService.ts`
- `src/vs/workbench/contrib/mcp/common/mcpTypesUtils.ts`
- `src/vs/workbench/contrib/mcp/common/mcpGatewayToolBrokerChannel.ts`
- `src/vs/workbench/contrib/mcp/common/mcpDevMode.ts`
- `src/vs/workbench/contrib/mcp/browser/mcpLanguageFeatures.ts`
- `src/vs/workbench/contrib/mcp/browser/mcpServerActions.ts`

## Source observations

- `McpRegistry._checkTrust()` first blocks workspace-scoped collections when Workspace Trust is absent. Non-interactive callers that set `errorOnUserInteraction` receive `UserInteractionRequiredError('workspaceTrust')` instead of prompting.
- `TrustedOnNonce` server definitions compare the current definition nonce to the last trusted nonce. Changed or unknown definitions prompt unless the caller passed `autoTrustChanges`.
- Non-interactive autostart in `McpService` calls `startServerAndWaitForLiveTools(server, { interaction, errorOnUserInteraction: true }, token)`, which should fail closed when Workspace Trust, server trust, or input variables would require UI.
- Gateway/tool-broker readiness calls use `promptType: 'all-untrusted'` and `errorOnUserInteraction: true`, so they should not silently approve trust or collect inputs while servicing an automatic request.
- `_replaceVariablesInLaunch()` checks unresolved variables and throws `UserInteractionRequiredError('variables')` when `errorOnUserInteraction` is set.
- `autoTrustChanges: true` appears in MCP language-feature code lenses for explicit Start/Restart/Debug actions. These are user-visible command surfaces, not background autostart paths.
- `startServerByFilter()` is used after install actions and starts matching newly installed servers with `promptType: 'all-untrusted'`; this follows an explicit install action. It does not set `autoTrustChanges`.
- MCP dev-mode auto-start calls `server.start()` when dev mode is enabled and a delegate can start the server. This does not pass `autoTrustChanges`, so changed TrustedOnNonce definitions should still go through normal trust handling. Because it is an automatic path, it remains worth runtime testing.

## Triage

Current status: **no bypass found in source review**.

The current source review supports the intended security posture: automatic/non-interactive paths fail closed when trust or variable input would require UI, while `autoTrustChanges` is limited to deliberate user-facing code-lens start/restart/debug actions.

Remaining risk areas:

1. Runtime validation of MCP dev-mode auto-start, because it is an automatic start path that does not use `errorOnUserInteraction`.
2. Ensuring every future or extension-contributed caller that passes `autoTrustChanges` is reachable only from a clear user action.
3. Confirming UI wording makes it clear that a workspace-defined MCP server may launch local commands.
4. Checking install flows where `startServerByFilter()` starts a server immediately after install, especially workspace-target installs.

No MSRC report should be drafted from this lead unless a runtime path starts a workspace-defined MCP server without Workspace Trust, server trust/nonce approval, or a clear user action.
