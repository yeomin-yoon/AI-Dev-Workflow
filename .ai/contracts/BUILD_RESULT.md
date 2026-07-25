# Contract: Build Result

Path: `.ai/lanes/<lane>/builds/BUILD-<TASK>-<ATTEMPT>.md`

```markdown
---
task: <id>
lane: <lane>
attempt: 1
status: ready_to_review
base_revision: <commit|working-tree>
result_revision: <commit|working-tree>
result_tree: <git-tree-hash|unsealed>
candidate_fingerprint: <git-tree:hash|sha256:hash|unsealed>
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

- The Baseline section is required for new attempts. Pre-v1.12 historical artifacts may omit it but cannot be used to prove change attribution.
- List only executed checks; use `not_run/unavailable` explicitly.
- Keep only decisive output excerpts and link the full log.
- Every changed path maps to the task or an AC.
- Capture pre-existing dirty paths before Builder writes. If no reliable baseline exists, use `unknown` and disclose the resulting attribution risk; never claim unrelated changes as this Task's work.
- For a non-`main` worktree candidate, `base_revision` and `result_revision` must be commits, `result_tree` must equal `result_revision^{tree}`, and `candidate_fingerprint` is `git-tree:<result_tree>`. Builder commits only Task-attributed production/test changes; the Build Result and other Lane workflow artifacts remain for the later metadata-only handoff commit.
- A single-`main` Build may use `working-tree` with `result_tree: unsealed`, but when Git is available it must record `candidate_fingerprint: sha256:<hash>`. It can be reviewed locally but is not eligible for cross-worktree Integration.
- If a non-`main` candidate cannot be isolated and committed safely, record it as unsealed, disclose the exact cause, and route an actionable prerequisite. Do not present a working-tree result as mergeable.
- Do not implement around an architecture/integration blocker.
- If implementation and available deterministic checks are complete, an unavailable user-observed/manual gate stays in `Unverified / Risks` and the candidate routes Reviewer; it does not by itself keep Builder blocked.
- Review PASS is required before acceptance.

For a Git-backed single-main working tree, calculate the fingerprint from a canonical UTF-8/LF manifest sorted by repository-relative Task path. Include the baseline revision plus, for every added/modified/deleted/renamed endpoint, its status, path, object kind/mode, and SHA-256 content hash or the literal `deleted`. Include untracked Task files. Hash that manifest with SHA-256. The same path set and algorithm must be used by Reviewer and downstream accepted-state consumers; a plain `git diff` that omits untracked files is insufficient.
