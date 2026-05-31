# Markdown preview and opener audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: repository-controlled Markdown links, raw HTML, and opener routing

This pass checked whether malicious Markdown content can cause command execution, unsafe protocol routing, external navigation, or script execution merely by opening a repository or Markdown preview.

Primary files reviewed:

- `extensions/markdown-language-features/src/markdownEngine.ts`
- `extensions/markdown-language-features/src/preview/preview.ts`
- `extensions/markdown-language-features/src/preview/documentRenderer.ts`
- `extensions/markdown-language-features/src/util/openDocumentLink.ts`
- `extensions/markdown-language-features/notebook/index.ts`
- `src/vs/editor/browser/services/openerService.ts`
- `src/vs/editor/contrib/links/browser/links.ts`
- `src/vs/workbench/browser/parts/editor/editorCommands.ts`
- `src/vs/workbench/contrib/url/browser/trustedDomainsValidator.ts`
- `src/vs/platform/url/common/trustedDomains.ts`

## Source observations

- Markdown preview webviews enable scripts for VS Code's preview runtime, but generated HTML is stored in escaped webview data attributes and the preview page includes a Content Security Policy in normal security modes.
- Strict Markdown preview CSP allows only nonce-bearing scripts, workspace/webview resources, HTTPS/data media, and inline styles. The `AllowScriptsAndAllContent` mode intentionally disables the CSP but is a user-selected preview security mode.
- The Markdown engine records original link text in `data-href`, while local `file:` and relative resources are converted through `asWebviewUri()` for preview rendering.
- Preview link activation calls the Markdown language server's `resolveLinkTarget()` and then routes external links through `vscode.commands.executeCommand('vscode.open', uri)` or files/folders through explicit open/reveal commands.
- The renderer-side `vscode.open` command explicitly refuses `command:` URIs, preventing the normal Markdown external-link path from becoming direct command execution.
- The generic `CommandOpener` executes `command:` URIs only when callers pass `allowCommands`; otherwise it consumes the URI without executing it. Editor text links pass `allowCommands: true` because they require editor link activation, while Markdown preview external links flow through `vscode.open` instead.
- HTTP/HTTPS opener validation prompts for untrusted external domains unless the workspace is trusted and `workbench.trustedDomains.promptInTrustedWorkspace` disables prompting. Localhost-style authorities are considered trusted by the trusted-domain helper.
- Notebook Markdown output sanitizes rendered Markdown when the workspace is untrusted, but uses unsanitized rendered Markdown when trusted. That is a notable trust-boundary behavior for future notebook-specific review, but not a malicious-repository-open bypass by itself.
- The Markdown extension declares `markdown.styles` as a restricted configuration, so repository-scoped styles should be ignored or warned about in untrusted workspaces.

## Local fixture

Added `fixtures/vscode-malicious-workspace/markdown-opener-links/` with:

- `sample.md` containing benign `command:`, encoded command, `vscode:`, `file:`, `http(s):`, localhost, and raw-HTML link/script shapes,
- workspace settings attempting to set `markdown.styles`, and
- a benign stylesheet to confirm whether restricted Markdown styling is applied only under expected trust/configuration conditions.

Expected safe runtime behavior: opening the folder and Markdown preview with a clean, initially untrusted profile must not execute commands, set script-controlled DOM markers, or silently navigate externally. Link activation should require explicit user action and should present/route targets according to the opener and trusted-domain rules.

## Triage

Current status: **no Markdown/opener command-execution bypass found in source review**.

This lead remains useful for runtime validation because Markdown involves multiple parsers and URI conversions. It is not report-ready unless a clean-profile runtime test shows repository Markdown can execute a VS Code command, run script, weaken preview security, or silently open a sensitive local/external target without clear user action and mediation.
