# Markdown preview and webview link audit pass

Date: 2026-05-31
Upstream checkout: `microsoft/vscode` shallow clone at commit `6b1e5513a8bab3688342b3b01de41d4a905b289f`.

## Lead: malicious Markdown preview content, webview CSP, and link routing

This pass reviewed whether repository-controlled Markdown can execute script or privileged VS Code commands when a victim opens Markdown Preview or notebook Markdown rendering.

Primary files reviewed:

- `extensions/markdown-language-features/src/preview/documentRenderer.ts`
- `extensions/markdown-language-features/src/preview/preview.ts`
- `extensions/markdown-language-features/preview-src/index.ts`
- `extensions/markdown-language-features/src/util/openDocumentLink.ts`
- `extensions/markdown-language-features/src/markdownEngine.ts`
- `extensions/markdown-language-features/notebook/index.ts`
- `extensions/markdown-language-features/package.json`

## Source observations

- The normal Markdown preview renders with `enableScripts: true`, but the generated document includes a CSP. In the default strict level, `script-src` is nonce-based and does not allow arbitrary inline script/event handlers from Markdown content.
- The preview security selector can move a resource to `AllowScriptsAndAllContent`, which removes the CSP, but that is a user-controlled global-state decision rather than repository-controlled default behavior.
- `markdown.styles` is a resource-scoped setting but is listed as a restricted configuration for untrusted workspaces. Extension-contributed preview scripts/styles come from installed extensions, not repository files by default.
- The preview webview click handler passes through `http:`, `https:`, `mailto:`, `vscode:`, and `vscode-insiders:` links to the browser/webview. Relative links are intercepted and sent to the extension host as `openLink` messages for resolution.
- `MdLinkOpener` resolves links through the Markdown language service and then calls `vscode.open` for external/file targets or `revealInExplorer` for folders. The reviewed preview path does not enable arbitrary `command:` URI execution.
- Notebook Markdown rendering sanitizes untrusted workspace output with DOMPurify; trusted workspaces render unsanitized Markdown output, which aligns with the Workspace Trust boundary for notebook output.

## Local fixture

Added `fixtures/vscode-malicious-workspace/markdown-preview-links/` with a Markdown sample containing relative, `command:`, `vscode:`, and encoded `https:` links plus raw HTML script/event-handler shapes. The fixture is intended for clean-profile manual preview validation.

Expected safe runtime behavior: opening the folder and preview should not execute inline script/event handlers or `command:` links. Relative links may open local files only after deliberate link activation, and protocol/external links should follow the normal webview/opener mediation.

## Triage

Current status: **no Markdown preview command execution or default-script bypass found in source review**.

This lead is not report-ready unless runtime validation shows default Markdown preview content can execute script, run internal commands, bypass CSP without the user lowering preview security, or make pass-through protocol links perform privileged actions without understandable user mediation.
