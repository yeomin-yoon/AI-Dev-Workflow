# Contract: Build Result

Path: `.ai/lanes/<lane>/builds/BUILD-<TASK>-<ATTEMPT>.md`

```markdown
---
task: <id>
lane: <lane>
attempt: 1
status: ready_to_review
base_revision: <full-commit|no-git>
result_revision: <commit|working-tree|no-git>
result_tree: <git-tree-hash|unsealed>
candidate_fingerprint: <sha256:hash|null|unsealed>
builder: <session-id|unknown>
---

# Build <Task>

## Outcome
<one short paragraph>

## Baseline
- pre-existing dirty paths: <paths|none|unknown>
- evidence: <status/diff ref>

## Changes
| Path | Change | AC/reason |
|---|---|---|

## AC Evidence
| AC | Result | Evidence |
|---|---|---|

## Checks
| Command/check | Result | Evidence/log path |
|---|---|---|

## Deviations
none

## Unverified / Risks
none

## Route
Reviewer
```

Use `candidate | ready_to_review | blocked | superseded`.

Rules:

- The Baseline section is required for every Build attempt.
- List only executed checks; use `not_run/unavailable` explicitly.
- Keep only decisive output excerpts and link the full log.
- Every changed path maps to the task or an AC.
- Capture pre-existing dirty paths before Builder writes. If no reliable baseline exists, use `unknown` and disclose the resulting attribution risk; never claim unrelated changes as this Task's work.
- When Git exists, `base_revision` is always the full `HEAD` commit captured before Builder writes. A dirty checkout does not turn the baseline into `working-tree`; disclose its pre-existing paths in Baseline. Use `no-git` only when the checkout has no usable Git commit.
- For a non-`main` worktree candidate, `base_revision` and `result_revision` must be commits, `result_tree` must equal `result_revision^{tree}`, and `candidate_fingerprint` is `null`; the immutable Git tree already identifies the candidate. The on-demand delivery procedure is in `MAIN_DESK.md`.
- A single-`main` Git Build uses `result_revision: working-tree`, `result_tree: unsealed`, and `candidate_fingerprint: sha256:<hash>`. It can be reviewed locally but is not eligible for cross-worktree Integration.
- A no-Git candidate uses `base_revision: no-git`, `result_revision: no-git`, `result_tree: unsealed`, and `candidate_fingerprint: unsealed`; disclose reduced attribution assurance.
- If a non-`main` candidate cannot be isolated and committed safely, record it as unsealed, disclose the exact cause, and route an actionable prerequisite. Do not present a working-tree result as mergeable.
- Do not implement around an architecture/integration blocker.
- If implementation and available deterministic checks are complete, an unavailable user-observed/manual gate stays in `Unverified / Risks` and the candidate routes Reviewer; it does not by itself keep Builder blocked.
- Review PASS is required before acceptance.

`candidate_fingerprint` exists only to bind a mutable single-main working tree. Its authoritative path set is the Build Result `Changes` table after Builder reconciles it with the Task `allowed_write`, baseline, Git status/diff, and untracked Task files. Every rename contributes its old endpoint as `deleted` and its new endpoint as content. If that complete Task-attributed set cannot be established, use `unsealed` and disclose reduced assurance.

Create this canonical UTF-8/LF manifest with tabs between fields. Write the `base` line exactly once as the fixed first header; it never participates in path sorting. Then ordinal-sort only the `path` rows by their normalized repository-relative path:

```text
base	<full base_revision>
path	<repository-relative path>	<tracked Git mode, regular, or deleted>	<sha256 of raw file bytes or deleted>
```

For a tracked path, use its exact index/tree mode such as `100644`, `100755`, or `120000`. For an untracked regular file, use the literal `regular`; never guess `100644`. A deleted endpoint uses `deleted` for both final fields. If a Task-attributed untracked entry has an unsupported/special file type that cannot be represented deterministically, use `unsealed` instead of inventing a token. Use `/` separators and one final LF, then SHA-256 hash the manifest bytes. Example input:

```text
base	0123456789abcdef0123456789abcdef01234567
path	!Generated/Local.txt	regular	5a2c...
path	Source/Game/New.cpp	100644	4f8c...
path	Source/Game/Old.cpp	deleted	deleted
```

Reviewer first proves the `Changes` table is complete, then uses exactly this path set and algorithm at Review start and immediately before PASS. Downstream accepted-state consumers load the accepted Review and its referenced Build Result, then reuse that `Changes` path set. A plain `git diff` that omits untracked files is insufficient. Historical committed Results that duplicated `git-tree:<result_tree>` remain readable, but new committed Results use `null`.
