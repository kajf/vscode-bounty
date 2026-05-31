# Git local-config helper audit pass

Date: 2026-05-30
Upstream checkout: `microsoft/vscode` shallow clone at commit `f6d1fcfcfcb5225125221ff6fdd6ae8c699958d5`.

## Lead: repository-local Git config helpers in a trusted workspace

This pass looked at Git-extension behavior when VS Code opens a folder that already contains a `.git` directory with repository-local configuration. This is different from a normal `git clone`: clone does not copy an attacker's `.git/config`, but zip/shared-folder scenarios can include a pre-existing local Git database.

Primary files reviewed:

- `extensions/git/package.json`
- `extensions/git/src/git.ts`
- `extensions/git/src/repository.ts`
- `extensions/git/src/quickDiffProvider.ts`
- `extensions/git/src/fileSystemProvider.ts`
- `src/vs/workbench/contrib/scm/browser/quickDiff.contribution.ts`
- `src/vs/workbench/contrib/scm/browser/quickDiffDecorator.ts`
- `src/vs/workbench/contrib/scm/browser/quickDiffModel.ts`

## Source observations

- The built-in Git extension declares `capabilities.untrustedWorkspaces.supported: false`, so it should not run inside an untrusted workspace.
- The Git wrapper spawns the configured Git binary with inherited environment plus VS Code-specific variables; it does not globally add `-c core.fsmonitor=false`, `-c diff.external=`, `--no-optional-locks`, or `--no-ext-diff` to every Git command.
- Git status paths are important because repository discovery/status refresh is a normal Git extension activity. A repository-local `core.fsmonitor` helper can be invoked by plain `git status`.
- Git diff paths are important because `GitFileSystemProvider.readFile()` calls `repository.diffWithHEAD(path)` or `repository.diffIndexWithHEAD(path)` for certain `git:` URIs, and those methods use plain `git diff ... -- <path>` without `--no-ext-diff`.
- Quick diff decorations default to `scm.diffDecorations: all`. The quick-diff workbench controller creates quick-diff models for visible resolved text editors, and the model resolves original resources through registered quick-diff providers. For Git, that original resource can be a `git:` URI whose read path reaches `git diff`.

## Local Git command confirmation

Benign local shell checks confirmed Git's baseline behavior outside VS Code:

- `git status --porcelain=v1` invokes a repository-local `core.fsmonitor` helper.
- `git diff -- tracked.txt` invokes a repository-local `diff.external` helper.
- `git diff --no-ext-diff -- tracked.txt` suppresses `diff.external`.

These checks do not prove VS Code exploitability by themselves; they show why the VS Code call sites deserve runtime validation.

## Fixture added

`fixtures/vscode-malicious-workspace/git-local-config-hooks/create-fixture.sh` creates a throwaway worktree with:

- a modified tracked file;
- a benign `core.fsmonitor` marker script;
- a benign `diff.external` marker script;
- repository-local Git config pointing at those scripts.

## Triage

Current status: **promising but not report-ready**.

Reasons this is not yet an MSRC-quality report:

1. The Git extension should be disabled until Workspace Trust is granted.
2. A normal remote `git clone` does not give the attacker control of the victim's `.git/config`.
3. The current evidence confirms Git behavior and VS Code source call sites, but not a clean-profile VS Code runtime reproduction.
4. Bounty relevance depends on whether a realistic in-scope malicious-repository-open flow can reach these helpers without adequate trust/consent, or whether VS Code should defensively suppress repository-local Git helpers even after trust.

## Next validation steps

1. Generate the fixture into `/tmp` and open the generated worktree in VS Code with clean `--user-data-dir` and `--extensions-dir`.
2. Before granting Workspace Trust, confirm no marker file is created by the Git extension.
3. After granting trust, observe whether `git status` appends `core.fsmonitor invoked` during repository discovery/status refresh.
4. Open `tracked.txt` and observe whether quick diff decorations or an explicit diff view append `diff.external invoked`.
5. Repeat after setting `scm.diffDecorations: none` to separate passive editor decoration behavior from explicit diff commands.
6. If marker execution happens before trust or without clear user action, prepare a full MSRC report. If it happens only after explicit trust, keep as hardening guidance unless a stronger bypass is found.
