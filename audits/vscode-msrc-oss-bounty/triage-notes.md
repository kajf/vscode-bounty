# Triage notes and dead ends

## Finding candidate A: `.vscode/tasks.json` automatic task command execution

- Scenario tested by fixture only: a repository defines a task with `runOptions.runOn: folderOpen` that writes a marker file in the workspace.
- Expected VS Code security behavior: the task should not silently execute merely because attacker-controlled repository content exists. It should require the relevant workspace trust state and automatic-task permission/setting.
- Bounty relevance: high only if the task runs without required trust/permission, if a workspace setting from the repository can grant that permission, or if another flow causes automatic tasks to execute unexpectedly.
- Current status: **not a vulnerability** based on source review. Existing public discussions document that automatic tasks are a feature and require an allow/manage step; local runtime validation is still pending.
- Next validation: run VS Code with a clean user-data-dir and extension-dir against `fixtures/vscode-malicious-workspace/tasks-autorun-marker`, verify no marker file is written before explicit user allow/trust, then inspect storage keys/configuration targets that persist the decision.

## Finding candidate B: manual task execution from malicious workspace

- Scenario tested by fixture only: a repository provides an obvious marker-writing shell task.
- Expected VS Code security behavior: manually selecting and running a workspace task is user-mediated command execution and generally not bounty-worthy by itself.
- Bounty relevance: low unless a UI spoofing, task-label confusion, or variable-resolution issue converts passive content into unexpected execution.
- Current status: **dead end for now**.

## Finding candidate C: markdown links and webview/link handling

- Scenario prepared for future work: benign markdown samples include `command:`, `vscode:`, `file:`, encoded, and HTML-based link shapes.
- Expected VS Code security behavior: markdown preview should sanitize dangerous HTML/script content, and link activation should not execute commands or privileged actions without explicit safe handling.
- Bounty relevance: medium to high if repository markdown can trigger XSS in a privileged webview, leak local files, or invoke commands without meaningful user consent.
- Current status: **source-reviewed but not runtime-validated**. No bypass was found in the markdown preview CSP/link handling review; runtime fuzzing remains pending.

## No MSRC report drafted

A report should only be drafted after a reproducible issue is validated against the latest actively maintained branch. This pass did not meet that threshold.

## Finding candidate D: workspace settings attempt to weaken trust/automation controls

- Scenario prepared by fixture: a repository-controlled `.vscode/settings.json` attempts to set `security.workspace.trust.enabled: false`, suppress trust UI, set `task.allowAutomaticTasks: on`, and override extension untrusted-workspace support.
- Source review result: the relevant settings are registered as application-scoped, and `task.allowAutomaticTasks` is also marked restricted. This should prevent the repository from granting itself automatic execution privileges or disabling Workspace Trust.
- Bounty relevance: high only if runtime testing shows these values are honored from workspace scope early enough to bypass trust, automatic-task permission, or built-in extension boundaries.
- Current status: **not a vulnerability** based on source review; runtime validation still needed with clean user data.


## Finding candidate E: debug `launch.json` preLaunchTask and command/input variables

- Scenario prepared by fixture: a repository-defined debug configuration references a marker-writing `preLaunchTask`.
- Source review result: debug start requests Workspace Trust before resolving and launching workspace debug code; configuration targets are preserved for launch input resolution; preLaunchTask execution is reached after explicit debug start.
- Bounty relevance: high only if another path starts debugging, resolves command inputs, or runs `preLaunchTask` without the trust request or a clear user action.
- Current status: **not a vulnerability** based on source review; runtime validation still needed.

## Finding candidate F: terminal output links with command/protocol/file URI shapes

- Scenario prepared by fixture: a manual task prints `command:`, `vscode:`, `vscode-insiders:`, `file:`, and encoded `https:` link-shaped strings.
- Source review result: terminal URL links require link activation and use `openExternal: true` without `allowCommands`; this should avoid the internal `CommandOpener` path for `command:` output even if workspace settings broaden `terminal.integrated.allowedLinkSchemes`.
- Bounty relevance: medium if runtime testing shows printed terminal output can execute an internal command, bypass allowed-scheme mediation, open a sensitive local file, or misrepresent the action to the user.
- Current status: **not a vulnerability** based on source review; fixture expanded and runtime validation still needed.


## Finding candidate G: repository-local Git config helpers (`core.fsmonitor`, `diff.external`)

- Scenario prepared by fixture generator: a folder with a pre-existing `.git/config` points `core.fsmonitor` and `diff.external` at benign marker scripts inside the worktree.
- Source review result: the built-in Git extension is unsupported in untrusted workspaces, but after trust it invokes ordinary Git status/diff paths. `git status` can invoke `core.fsmonitor`, while Git-backed quick diff and diff views can reach `git diff` without `--no-ext-diff`.
- Local Git command confirmation: outside VS Code, `git status --porcelain=v1` invoked the fsmonitor marker and `git diff -- tracked.txt` invoked the external-diff marker; `git diff --no-ext-diff -- tracked.txt` suppressed only the external diff helper.
- Bounty relevance: potentially high only if VS Code reaches these helpers before Workspace Trust, from a normal in-scope clone/open flow, or without meaningful user consent. If execution occurs only after explicit trust of a folder containing attacker-controlled `.git/config`, this is more likely hardening guidance than a bounty-quality issue.
- Current status: **promising but not report-ready**; clean-profile VS Code runtime validation is required.


## Finding candidate H: MCP trust/autostart and `autoTrustChanges`

- Scenario reviewed: workspace-defined MCP servers, automatic server startup, install-triggered startup, code-lens Start/Restart/Debug actions, and changed TrustedOnNonce definitions.
- Source review result: background/autostart paths generally use `errorOnUserInteraction: true` and should fail closed when Workspace Trust, server trust, or input variables would require UI. `autoTrustChanges: true` was observed on user-facing code-lens Start/Restart/Debug actions, not background autostart.
- Bounty relevance: high only if a workspace-defined MCP server can start local commands before Workspace Trust, without server trust/nonce approval, or through an automatic path that silently auto-trusts changed definitions.
- Current status: **no bypass found in source review**; runtime validation remains worthwhile for MCP dev-mode autostart and post-install start flows.


## Finding candidate I: built-in task-provider discovery

- Scenario prepared by fixture: a repository contains `package.json`, `gulpfile.js`, and a fake local `node_modules/.bin/gulp` shim that writes a benign marker when task discovery invokes it.
- Source review result: npm discovery reads `package.json` and creates task objects without running scripts; gulp/grunt/jake discovery can execute local listing commands, but their auto-detect settings default off and task listing/running paths are guarded by the central task-service Workspace Trust prompt.
- Bounty relevance: high only if default task discovery or task execution can reach repository-controlled commands before Workspace Trust, without the task-listing prompt, or without the relevant user/application setting.
- Current status: **no bypass found in source review**; clean-profile runtime validation is pending for marker absence before trust and expected marker creation only after explicit trust plus provider opt-in.


## Finding candidate J: terminal allowed-link schemes and opener routing

- Scenario prepared by fixture: workspace settings add `command` and `foo+bar` to `terminal.integrated.allowedLinkSchemes`, then a manual task prints `command:`, `vscode:`, `file:`, `https:`, and custom-scheme URI text.
- Source review result: terminal link activation requires a user gesture; unknown schemes prompt before being added; terminal URL opening uses `openExternal: true` and does not set `allowCommands`, so `command:` output should not reach the internal command opener.
- Bounty relevance: high only if terminal output can execute internal VS Code commands or bypass scheme/user mediation from repository-controlled output.
- Current status: **no bypass found in source review**; clean-profile runtime validation is pending because `terminal.integrated.allowedLinkSchemes` is workspace-configurable and worth observing in practice.


## Finding candidate K: Markdown preview CSP and link routing

- Scenario prepared by fixture: Markdown content includes raw HTML script/event-handler shapes plus relative, `command:`, `vscode:`, and encoded `https:` links.
- Source review result: default Markdown preview uses nonce-based CSP despite `enableScripts: true`; `markdown.styles` is restricted in untrusted workspaces; relative links are resolved through the Markdown extension; reviewed preview link handling does not enable arbitrary `command:` execution.
- Bounty relevance: high only if repository Markdown can execute script or internal commands under default preview security, or can make pass-through protocol links perform privileged actions without understandable user mediation.
- Current status: **no bypass found in source review**; clean-profile runtime validation is pending.
