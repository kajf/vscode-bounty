# Markdown preview benign security samples

This fixture intentionally contains link and HTML shapes that are useful for observing Markdown preview behavior. They are benign markers only.

- Relative file link: [open local note](./note.md#L1)
- Command-shaped link: [command link should not execute](command:workbench.action.showCommands)
- VS Code protocol-shaped link: [vscode protocol link](vscode://file/tmp/example.txt)
- HTTP link with encoded characters: [encoded URL](https://example.com/%2Bplus?x=%2520)

Raw HTML/event-handler shapes for CSP observation:

<img src="missing-image-for-csp-test.png" onerror="document.body.setAttribute('data-inline-handler-ran','yes')" alt="missing image">

<script>document.body.setAttribute('data-inline-script-ran','yes')</script>
