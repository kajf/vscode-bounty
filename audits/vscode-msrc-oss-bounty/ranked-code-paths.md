# Ranked malicious-workspace audit targets

Ranking uses bounty relevance, exploit plausibility, and ability to produce public security value without attacking live services.

| Rank | Area | Code paths / artifacts to prioritize | Why it matters | Initial triage status |
|---:|---|---|---|---|
| 1 | Workspace trust gates | `src/vs/platform/workspace/common/workspaceTrust.ts`; workbench services that call `IWorkspaceTrustManagementService` and `IWorkspaceTrustRequestService` | A trust bypass could turn normal repository-open behavior into code execution or data exposure. | Not validated. Need local source and tests. |
| 2 | Automatic tasks | `src/vs/workbench/contrib/tasks/browser/runAutomaticTasks.ts`; `src/vs/workbench/contrib/tasks/common/taskConfiguration.ts`; `.vscode/tasks.json` | `runOptions.runOn: folderOpen` is an intentional command-execution feature; bounty-worthy only if it runs without trust/permission or bypasses policy. | Reviewed at policy level; fixture added; no bypass found. |
| 3 | Manual task execution and variable resolution | `abstractTaskService.ts`, `terminalTaskSystem.ts`, configuration resolver service, task inputs | Command strings, `${...}` substitutions, shell/process mode, env/cwd and task inputs are classic injection surfaces. | Needs local clone. Benign fixture added. |
| 4 | Debug launch configurations | debug service, configuration manager/resolver, extension-contributed debuggers, `.vscode/launch.json` | `preLaunchTask`, debug adapters, and compound configs can lead to local process execution; bounty-worthy only if attacker content crosses consent/trust boundaries. | Not yet validated. |
| 5 | Workspace settings | configuration service, restricted settings schema, workspace-trust filtering | Malicious settings can influence terminals, extensions, markdown, tasks, and Git; need to verify restricted settings cannot silently weaken trust. | Not yet validated. |
| 6 | Markdown rendering and webviews | markdown renderer, markdown preview extension, sanitizer, link handling, command URI handling | XSS or command URI abuse in markdown preview/webviews could be significant if reachable from repository content. | Not validated; add XSS/link fixture next. |
| 7 | Terminal links/providers | terminal link manager, local/remote file link resolver, opener service | Terminal output from tasks or build scripts may contain links; command/file URI parsing mistakes can create clickjacking or command invocation risks. | Not validated. |
| 8 | Protocol handlers and URL/file parsing | opener service, trusted domains, URL handlers, `vscode://`/`vscode-insiders://` handlers | URI parsing confusion could cause unexpected file open, command execution, or trust prompts bypasses. | Not validated. |
| 9 | Git clone/open-folder flows | Git extension, clone UI, folder open/reload flow, workspace trust transition code | Clone/open flows are directly relevant to malicious repository attacks. | Not validated; do not exercise against live services beyond normal source fetches. |
| 10 | Extension host boundaries | extension host activation events, workspace trust capabilities, built-in extensions only | Bounty excludes non-default extensions, but default/built-in extension activation from workspace content remains relevant. | Not validated. |

## Highest-priority next checks after a successful clone

1. Grep for workspace-trust checks around automatic task execution and confirm exact ordering: workspace trusted, automatic tasks allowed, then task resolution/execution.
2. Trace `.vscode/tasks.json` parsing through command construction and terminal spawning for shell quoting edge cases.
3. Confirm workspace settings marked as restricted cannot be changed by a malicious repository to enable automatic tasks or command URIs.
4. Trace markdown preview sanitizer and link activation rules for `command:`, `vscode:`, `file:`, and encoded/redirected variants.
5. Review opener/trusted-domain code for URL canonicalization, wildcard handling, punycode/IDNA, and authority confusion.
