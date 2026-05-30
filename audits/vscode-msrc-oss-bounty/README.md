# VS Code malicious-workspace security audit notes

Date: 2026-05-30
Target: `microsoft/vscode`
Primary scenario: a victim opens an attacker-controlled repository or workspace in VS Code.

## Scope and rules read

- Microsoft Open Source Bounty Program page, read 2026-05-30: Visual Studio Code is listed in scope; qualifying submissions must be Critical or Important severity, reproducible on the most recent actively maintained branch, and demonstrate direct customer security impact. The page lists examples such as deserialization, remote code execution, XSS, and elevation of privilege; it also calls out out-of-scope cases such as public/known issues, issues requiring extensive or unlikely user actions, vulnerabilities relying on non-default VS Code extensions, and issues without qualifying impact on the specified service.
- VS Code GitHub security policy, read 2026-05-30: security vulnerabilities should not be reported through public GitHub issues and should follow Microsoft security reporting guidance.
- Research constraints followed in this pass: no live Microsoft service scanning, no public issue filing, no automatic submission, and only benign local fixture content.

## Environment and setup status

- Container working directory: `/workspace/vscode-bounty`.
- Current branch before committing notes: `work`.
- Local clone: `git clone --depth=1 https://github.com/microsoft/vscode.git repos/vscode` succeeded in this pass.
- Upstream commits audited: initial source pass at `1f98b39208918cace8d36e2a4f20b7b9282508f1`; deeper pass at `f6d1fcfcfcb5225125221ff6fdd6ae8c699958d5`.
- Full build/run status: not attempted in these passes; source review and fixture preparation were completed, and future runtime validation should use a clean VS Code profile.
- Local fixture content remains benign and marker-based only.

## Upstream version anchors observed

- GitHub repository page read 2026-05-30 showed branch `main`, repository `microsoft/vscode`, and latest release `1.122.1` dated 2026-05-29.
- Local source checkout confirmed the expected source layout including `src`, `extensions`, `.vscode`, `remote`, `cli`, `build`, and top-level `SECURITY.md`.

## Initial conclusion

No validated, reproducible in-scope vulnerability was found in the source-audit passes. No MSRC report draft is included because the current findings are expected VS Code behavior, source-review-only leads, or require runtime validation against a clean local VS Code profile.
