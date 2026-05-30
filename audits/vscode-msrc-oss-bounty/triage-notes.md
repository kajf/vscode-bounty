# Triage notes and dead ends

## Finding candidate A: `.vscode/tasks.json` automatic task command execution

- Scenario tested by fixture only: a repository defines a task with `runOptions.runOn: folderOpen` that writes a marker file in the workspace.
- Expected VS Code security behavior: the task should not silently execute merely because attacker-controlled repository content exists. It should require the relevant workspace trust state and automatic-task permission/setting.
- Bounty relevance: high only if the task runs without required trust/permission, if a workspace setting from the repository can grant that permission, or if another flow causes automatic tasks to execute unexpectedly.
- Current status: **not a vulnerability** based on this pass. Existing public discussions document that automatic tasks are a feature and require an allow/manage step; the initial local clone/build needed to test bypasses was blocked.
- Next validation: after source checkout, run VS Code with a clean user-data-dir and extension-dir against `fixtures/vscode-malicious-workspace/tasks-autorun-marker`, verify no marker file is written before explicit user allow/trust, then inspect storage keys/configuration targets that persist the decision.

## Finding candidate B: manual task execution from malicious workspace

- Scenario tested by fixture only: a repository provides an obvious marker-writing shell task.
- Expected VS Code security behavior: manually selecting and running a workspace task is user-mediated command execution and generally not bounty-worthy by itself.
- Bounty relevance: low unless a UI spoofing, task-label confusion, or variable-resolution issue converts passive content into unexpected execution.
- Current status: **dead end for now**.

## Finding candidate C: markdown links and webview/link handling

- Scenario prepared for future work: benign markdown samples include `command:`, `vscode:`, `file:`, encoded, and HTML-based link shapes.
- Expected VS Code security behavior: markdown preview should sanitize dangerous HTML/script content, and link activation should not execute commands or privileged actions without explicit safe handling.
- Bounty relevance: medium to high if repository markdown can trigger XSS in a privileged webview, leak local files, or invoke commands without meaningful user consent.
- Current status: **not validated** because source checkout/build and VS Code runtime were unavailable.

## No MSRC report drafted

A report should only be drafted after a reproducible issue is validated against the latest actively maintained branch. This pass did not meet that threshold.
