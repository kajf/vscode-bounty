# Markdown link handling samples

Use these benign samples to observe preview sanitization, link target display, and opener prompts. Do not add destructive command payloads.

- Plain command URI shape: [command sample](command:workbench.action.showCommands)
- Encoded command URI shape: [encoded command sample](command%3Aworkbench.action.showCommands)
- VS Code protocol shape: [vscode sample](vscode://file/tmp/example.txt)
- File URI shape: [file sample](file:///tmp/example.txt)
- HTML link shape: <a href="command:workbench.action.showCommands">html command sample</a>
- Script-like HTML should be inert: <script>document.body.dataset.fixtureScriptRan = 'true'</script>
