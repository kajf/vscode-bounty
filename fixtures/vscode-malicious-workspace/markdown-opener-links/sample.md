# Markdown opener/link samples

This file is intentionally benign. It contains link and HTML shapes that should require explicit user activation and clear mediation in VS Code Markdown preview.

## Command and protocol-looking links

- [command URI sample](command:workbench.action.openSettings?%5B%22security.workspace.trust.enabled%22%5D)
- [encoded command URI sample](command%3Aworkbench.action.openSettings%3F%255B%2522security.workspace.trust.enabled%2522%255D)
- [vscode protocol sample](vscode://file/tmp/does-not-exist)
- [vscode-insiders protocol sample](vscode-insiders://file/tmp/does-not-exist)
- [file URI sample](file:///tmp/does-not-exist)
- [external HTTPS sample](https://example.com/path?x=command%3Aworkbench.action.openSettings)
- [localhost HTTPS-looking sample](http://localhost:65535/no-server)

## Raw HTML samples

<a href="command:workbench.action.openSettings?%5B%22markdown.preview.security.level%22%5D">raw HTML command link</a>

<img src=x onerror="document.body.dataset.markdownFixture='unexpected-script-execution'">

<script>document.body.dataset.markdownFixture = 'unexpected-script-execution';</script>
