# Built-in extension trust and activation audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: extension activation from malicious workspace contents

This pass reviewed whether repository content can activate built-in/default extensions in an untrusted workspace and cross the extension-host trust boundary before Workspace Trust.

Primary files reviewed:

- `src/vs/workbench/services/extensions/common/workspaceContains.ts`
- `src/vs/workbench/services/extensions/common/extensionManifestPropertiesService.ts`
- `src/vs/workbench/services/extensionManagement/browser/extensionEnablementService.ts`
- `src/vs/workbench/services/extensionManagement/common/extensionManagementService.ts`
- `src/vs/workbench/contrib/extensions/browser/extensions.contribution.ts`
- `src/vs/workbench/contrib/extensions/browser/extensionEnablementWorkspaceTrustTransitionParticipant.ts`
- built-in extension `package.json` manifests under `extensions/`

## Source observations

- Among built-in extensions in the audited checkout, `npm` was the only extension with a `workspaceContains:*` activation event (`workspaceContains:package.json`). It declares limited untrusted-workspace support.
- `workspaceContains` activation checks use direct file existence checks for exact names and file search for glob patterns; this can activate an extension based on repository files, but activation is still subject to extension enablement/trust state.
- `ExtensionManifestPropertiesService.getExtensionUntrustedWorkspaceSupportType()` uses user/application overrides, product overrides, and manifest capabilities to determine support. If Workspace Trust is disabled or an extension has no entry point, support is treated as true.
- `extensions.supportUntrustedWorkspaces` is registered with `ConfigurationScope.APPLICATION`, so repository workspace settings should not be able to override an extension into full untrusted-workspace support.
- `ExtensionEnablementService` disables extensions in untrusted workspaces when the extension is located inside the workspace or when its untrusted-workspace support type is false. Dependencies disabled by trust can also disable dependents.
- Extension enablement is recomputed when Workspace Trust changes; on trusted-to-untrusted transitions the extension host is stopped/reloaded before enablement changes are applied.
- Extension install/enable flows request Workspace Trust when an extension requires trust. The install path offers an explicit trust/continue choice unless trust is strictly required.
- The remaining built-in-extension risk is not generic activation itself, but a specific built-in extension that declares untrusted support and performs unsafe repository-driven behavior before trust. The earlier npm/task-provider pass covers the one built-in `workspaceContains` activation case found here.

## Triage

Current status: **no generic extension activation trust-boundary bypass found in source review**.

This lead is not report-ready unless runtime validation identifies a built-in/default extension that is enabled in untrusted workspaces and performs repository-controlled command execution, file writes, or data exposure merely because a matching file exists or an activation event fires.
