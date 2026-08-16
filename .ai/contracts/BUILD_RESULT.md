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
| Path | Attribution | Evidence |
|---|---|---|
| <path|none> | <unrelated_pre_existing|inherited_task|unknown> | <status/diff/Build ref> |

## Changes
| Path | Change | AC/reason | Source role / key symbol |
|---|---|---|---|
| <path or none> | <add/modify/delete> | <AC/reason> | <plain role + path#symbol; whole file; generated/mechanical; or n/a> |

## Source Map
- primary read: <three-to-five path#symbol anchors in runtime order|none>
- runtime flow: <entry -> important decision/state -> observable effect|none>
- new source files: <whole-file paths|none>
- generated/mechanical group: <paths or category|none>

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

- The Baseline section is required for every Build attempt. Before current-attempt writes, classify every already-dirty path as `unrelated_pre_existing | inherited_task | unknown`; current-attempt writes belong in `Changes`, not Baseline.
- List only executed checks; use `not_run/unavailable` explicitly.
- Keep only decisive output excerpts and link the full log.
- Every changed path maps to the task or an AC.
- For every Task-touched hand-written production source path in `Changes`, record its key symbol, plain-language role, and Task-specific reason in that row. The `Source Map` selects only the three-to-five anchors that best explain entry, important decision/state, and observable effect; it never repeats the full inventory. Mark a newly added source as `whole file`, group generated/vendor/mechanical paths, and omit the map only when no hand-written production source changed.
- Builder owns this revision-scoped Source Map while implementing. It exposes at most three current anchors after the first coherent edit, reports only material map deltas during Build, and gives the final primary read before Review handoff. The map is orientation rather than architecture or permanent Knowledge; Reviewer independently checks it against the exact candidate.
- Historical completed Build Results with the three-column `Changes` table and no `Source Map` remain readable and are never rewritten merely for this presentation change. Before a still-active historical candidate first enters Review under this contract, Builder reconstructs the missing role/symbol column and Source Map from the exact current candidate; accepted historical evidence needs no migration.
- `unrelated_pre_existing` requires evidence that the path predates the applicable Workflow attempt and is not attributable to it. Preserve it and never claim it as this Task's work.
- `inherited_task` means bytes attributable to an interrupted or superseded Workflow attempt. Preserve that attribution across Task/attempt IDs and reconcile it against the active Task's explicit `retain | adapt | remove` disposition when one is required.
- Use `unknown` when evidence cannot distinguish the two. Route the attribution gap as `context`; do not relabel the path as user work or silently include it in a candidate. Historical Build Results with the older Baseline bullets remain readable, but they cannot support an interrupted-attempt resume or supersession when attribution is ambiguous.
- When Git exists, `base_revision` is always the full `HEAD` commit captured before Builder writes. A dirty checkout does not turn the baseline into `working-tree`; disclose its pre-existing paths in Baseline. Use `no-git` only when the checkout has no usable Git commit.
- For a non-`main` worktree candidate, `base_revision` and `result_revision` must be commits, `result_tree` must equal `result_revision^{tree}`, and `candidate_fingerprint` is `null`; the immutable Git tree already identifies the candidate. The on-demand delivery procedure is in `MAIN_DESK.md`.
- A single-`main` Git Build uses `result_revision: working-tree`, `result_tree: unsealed`, and `candidate_fingerprint: sha256:<hash>`. It can be reviewed locally but is not eligible for cross-worktree Integration.
- A no-Git candidate uses `base_revision: no-git`, `result_revision: no-git`, `result_tree: unsealed`, and `candidate_fingerprint: unsealed`; disclose reduced attribution assurance.
- If a non-`main` candidate cannot be isolated and committed safely, record it as unsealed, disclose the exact cause, and route an actionable prerequisite. Do not present a working-tree result as mergeable.
- Do not implement around an architecture/integration blocker.
- If implementation and available deterministic checks are complete, an unavailable observation-only user/manual gate stays in `Unverified / Risks` and the candidate routes Reviewer; it does not by itself keep Builder blocked. Known user/editor authoring that saves Task-attributed bytes is implementation and must finish inside the active Build attempt before this Result becomes `ready_to_review`.
- `Unverified / Risks` may record an `observed` fact or explicitly `inferred` hypothesis needed to continue the current attempt. It never labels an inference `confirmed`, rewrites approved intent, or turns a hypothesis into Architecture/Task/state/Knowledge truth. When later evidence disproves it, correct the current Build Result before handoff and preserve only the evidence needed to explain the resulting route.
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
