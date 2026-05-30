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
- Attempted local clone: `git clone --depth=1 https://github.com/microsoft/vscode.git repos/vscode`.
- Result: blocked by the container network/proxy with `CONNECT tunnel failed, response 403`.
- Attempted tarball probe: `curl -I -L https://github.com/microsoft/vscode/archive/refs/heads/main.tar.gz`.
- Result: blocked by the same `CONNECT tunnel failed, response 403` limitation.
- Because the source tree could not be cloned in this container, this initial pass used browser-accessible upstream pages plus local benign fixtures and did not build or run VS Code.

## Upstream version anchors observed

- GitHub repository page read 2026-05-30 showed branch `main`, repository `microsoft/vscode`, and latest release `1.122.1` dated 2026-05-29.
- The repository page showed the expected source layout including `src`, `extensions`, `.vscode`, `remote`, `cli`, `build`, and top-level `SECURITY.md`.

## Initial conclusion

No validated, reproducible in-scope vulnerability was found in this initial environment-limited pass. No MSRC report draft is included because the current findings are either expected VS Code behavior, blocked from local validation, or require additional source/build work.
