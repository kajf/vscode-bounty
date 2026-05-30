# External sources consulted

- Microsoft Open Source Bounty Program: https://www.microsoft.com/en-us/msrc/opensourcebountyprogram
- VS Code GitHub security policy: https://github.com/microsoft/vscode/security/policy
- VS Code repository page: https://github.com/microsoft/vscode
- Public VS Code issue about `runOn: folderOpen`: https://github.com/microsoft/vscode/issues/160013
- Public VS Code issue about automatic tasks running twice: https://github.com/microsoft/vscode/issues/75758
- Stack Overflow discussion summarizing automatic task allow behavior: https://stackoverflow.com/a/72947814/126352

These sources are references for audit orientation only. Any actual vulnerability report must be based on a local reproduction against the latest actively maintained branch.

- Local source audit notes: `audits/vscode-msrc-oss-bounty/source-audit-2026-05-30.md`
- Local VS Code checkout: `repos/vscode` at commit `1f98b39208918cace8d36e2a4f20b7b9282508f1` (ignored by git).
- Local deep audit notes: `audits/vscode-msrc-oss-bounty/deep-audit-2026-05-30.md`
- Public VS Code issue about historical `task.allowAutomaticTasks` value/target regression: https://github.com/microsoft/vscode/issues/158285
- VS Code terminal issues wiki for terminal-link testing context: https://github.com/microsoft/vscode/wiki/Terminal-Issues
