# markdown-opener-links fixture

Benign fixture for validating Markdown preview and opener behavior with repository-controlled link-like content.
Open `sample.md` in Markdown Preview using a clean VS Code profile and an initially untrusted workspace.
No marker file should be created merely by opening the folder or preview.
Only record UI prompts/link targets; do not approve unexpected command execution or external navigation during validation.
