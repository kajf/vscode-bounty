# Restricted workspace-settings audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: repository settings that try to weaken Workspace Trust or automation controls

This pass reviewed whether a malicious repository can use `.vscode/settings.json` to disable Workspace Trust, enable automatic tasks, override extension trust support, or load unsafe Markdown preview resources before trust.

Primary files reviewed:

- `src/vs/platform/configuration/common/configurationModels.ts`
- `src/vs/platform/configuration/common/configurationRegistry.ts`
- `src/vs/workbench/api/common/configurationExtensionPoint.ts`
- `src/vs/workbench/services/workspaces/common/workspaceTrust.ts`
- `src/vs/workbench/contrib/tasks/browser/task.contribution.ts`
- `src/vs/workbench/contrib/tasks/browser/runAutomaticTasks.ts`
- `src/vs/workbench/contrib/extensions/browser/extensions.contribution.ts`
- `extensions/markdown-language-features/package.json`

## Source observations

- Configuration schemas can mark settings as `restricted`; parser models track restricted keys and can skip them when evaluating untrusted workspace values.
- Extension-contributed restricted settings are populated from `capabilities.untrustedWorkspaces.restrictedConfigurations` when an extension declares limited untrusted-workspace support.
- `task.allowAutomaticTasks` is application-scoped, restricted, defaults to `off`, and its description explicitly states automatic tasks do not run in untrusted workspaces.
- The automatic-task runner returns immediately when Workspace Trust is absent, then only inspects `task.allowAutomaticTasks` after the workspace is trusted.
- Workspace Trust control keys include `security.workspace.trust.enabled` and `extensions.supportUntrustedWorkspaces`; the extension trust override setting is application-scoped.
- The Markdown extension declares `markdown.styles` as restricted via its limited untrusted-workspace support metadata.

## Triage

Current status: **no restricted-settings bypass found in source review**.

The existing `fixtures/vscode-malicious-workspace/settings-restricted/` and new Markdown opener fixture remain useful runtime checks. This lead is not report-ready unless a clean-profile test shows repository-scoped settings are applied in a way that disables Workspace Trust, enables automatic execution, overrides extension trust boundaries, or loads restricted Markdown preview resources before trust.
