# Source audit pass: VS Code malicious-workspace surfaces

Date: 2026-05-30
Upstream checkout: `microsoft/vscode` shallow clone at commit `1f98b39208918cace8d36e2a4f20b7b9282508f1` (`Avoid leaving detached DOM elements in Getting Started (#319128)`).

## Setup notes

- Local clone path: `repos/vscode` (ignored by this repository).
- Clone command used: `git clone --depth=1 https://github.com/microsoft/vscode.git repos/vscode`.
- Build/run status: source was cloned successfully, but a full VS Code build was not attempted in this pass because the goal was to preserve time for initial attack-surface mapping and fixture creation. Future validation should run the fixtures against a built or released VS Code with clean user data.

## Policy anchors

- Microsoft Open Source Bounty Program page was re-read on 2026-05-30. VS Code is in scope; qualifying reports need Critical/Important severity, latest active branch reproducibility, and a direct demonstrable customer security impact.
- VS Code `SECURITY.md` in the cloned source says not to report vulnerabilities through public GitHub issues and to use Microsoft security guidance.

## Audited path 1: automatic tasks on folder open

Primary files reviewed:

- `src/vs/workbench/contrib/tasks/browser/runAutomaticTasks.ts`
- `src/vs/workbench/contrib/tasks/browser/task.contribution.ts`
- `src/vs/workbench/contrib/tasks/common/taskConfiguration.ts`
- `src/vs/workbench/contrib/tasks/common/tasks.ts`

Observed control flow:

1. `RunAutomaticTasks._tryRunTasks()` returns immediately when `IWorkspaceTrustManagementService.isWorkspaceTrusted()` is false.
2. It inspects `task.allowAutomaticTasks`; an explicit user value of `off` prevents prompting/running.
3. It discovers workspace tasks and filters only tasks whose parsed `runOptions.runOn` is `RunOnOptions.folderOpen`.
4. `_runWithPermission()` runs tasks only if the effective configuration value is `on`; otherwise it prompts once per workspace storage scope before running.
5. The `task.allowAutomaticTasks` setting is registered as `ConfigurationScope.APPLICATION`, `restricted: true`, and defaults to `off`, so a repository `.vscode/settings.json` should not be able to turn it on for itself.

Initial triage: no bypass found in source review. The dangerous primitive is intentional but appears gated by both workspace trust and a user/application-scoped automatic-task allow decision. The next validation step is runtime confirmation with the `tasks-autorun-marker` fixture and a clean profile.

## Audited path 2: Workspace Trust enablement and restricted settings

Primary files reviewed:

- `src/vs/workbench/services/workspaces/common/workspaceTrust.ts`
- `src/vs/workbench/contrib/workspace/browser/workspace.contribution.ts`
- `src/vs/workbench/services/configuration/test/browser/configurationService.test.ts`
- `src/vs/workbench/contrib/extensions/browser/extensions.contribution.ts`

Observed control flow and settings posture:

- `WorkspaceTrustEnablementService.isWorkspaceTrustEnabled()` returns false only if the process environment disables workspace trust or if the configuration value for `security.workspace.trust.enabled` is false.
- The trust enablement and prompt/banner/untrusted-file controls are registered as application-scoped settings, not workspace-scoped settings.
- The extension override setting `extensions.supportUntrustedWorkspaces` is also registered as application-scoped.
- Configuration service tests cover restricted settings not being read from workspace configuration in an untrusted workspace.

Fixture added: `fixtures/vscode-malicious-workspace/settings-restricted` attempts to set `security.workspace.trust.enabled`, startup prompt/banner behavior, `task.allowAutomaticTasks`, and `extensions.supportUntrustedWorkspaces` from repository-controlled workspace settings. Expected safe result: these workspace values do not grant trust, suppress trust UI in a security-relevant way, or globally allow automatic tasks.

Initial triage: no validated vulnerability. The main residual risk to test is whether any UI or initialization path reads raw workspace settings before target/scope/restriction filtering is applied.

## Audited path 3: Markdown preview, HTML, CSP, and links

Primary files reviewed:

- `extensions/markdown-language-features/src/markdownEngine.ts`
- `extensions/markdown-language-features/src/preview/documentRenderer.ts`
- `extensions/markdown-language-features/preview-src/index.ts`
- `extensions/markdown-language-features/src/preview/preview.ts`
- `extensions/markdown-language-features/src/util/openDocumentLink.ts`
- `extensions/markdown-language-features/src/preview/security.ts`

Observed control flow:

- The markdown engine uses `markdown-it` with `html: true`, so raw HTML from repository markdown can enter the preview DOM.
- The preview document wraps rendered markdown in a webview and applies a default strict CSP with `default-src 'none'`, nonce-gated extension scripts, and restricted image/media/style/font sources.
- The preview security selector stores security level decisions in extension global state by workspace root; allowing scripts/all content is an explicit user-selected unsafe mode.
- Click handling preserves `data-href` for original markdown links. Relative links are posted back to the extension for resolution. `http:`, `https:`, `mailto:`, `vscode:`, and `vscode-insiders:` links can pass through as normal anchors when no `data-href` is present.
- For extension-mediated opens, `MdLinkOpener.openDocumentLink()` asks the markdown language client to resolve the target and then invokes `vscode.open` for external/file targets or `revealInExplorer` for folders.

Initial triage: no validated vulnerability. Areas worth a deeper pass are link canonicalization differences between `href` and `data-href`, encoded scheme forms, and whether any `command:` link shape can reach `vscode.open` or webview navigation without a meaningful user gesture/prompt. The existing markdown fixture covers benign `command:`, encoded `command%3A`, `vscode:`, `file:`, HTML link, and script-like HTML shapes.

## Audited path 4: MCP workspace-defined servers

Primary files reviewed:

- `src/vs/workbench/contrib/mcp/common/mcpRegistry.ts`

Observed control flow:

- `_checkTrust()` blocks workspace-scoped MCP server definitions when the workspace is untrusted by requesting workspace trust or throwing `UserInteractionRequiredError` when interaction is disallowed.
- After workspace trust, MCP server trust behavior still distinguishes already trusted definitions, nonce-pinned definitions, and untrusted/changed definitions.

Initial triage: promising surface because MCP server definitions can launch local tools, but no bypass was found in this shallow pass. Deeper review should trace configuration ingestion and all call sites that pass `autoTrustChanges` or `errorOnUserInteraction`.

## Ranked next work

1. Runtime-test `tasks-autorun-marker` plus `settings-restricted` with clean `--user-data-dir` and `--extensions-dir`; verify marker absence before explicit trust/allow.
2. Trace `task.allowAutomaticTasks` effective value by configuration target during fixture runtime; verify workspace-level value is ignored.
3. Fuzz markdown preview link shapes locally: encoded schemes, mixed-case schemes, whitespace/control prefixing, HTML entity encoding, and nested anchors.
4. Review `vscode://`/`vscode-insiders://` opener handling and trusted-domain prompts for command/file opener confusion.
5. Trace MCP workspace server registration through all automatic start paths and nonce trust decisions.
6. Review debug `launch.json` and `preLaunchTask` trust boundaries after automatic tasks are fully validated.

## Current finding status

No validated, reproducible, in-scope vulnerability was found in this pass. No MSRC report should be submitted based on these notes alone.
