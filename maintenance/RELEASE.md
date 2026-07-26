# Distribution Release Maintenance

This source-only procedure exists in the canonical AI Dev Workflow distribution checkout. It is deliberately outside `.ai`, so ordinary project installations receive only local Observation capture rules. Read `.ai/maintenance/MAINTAIN.md` for the Observation schema and deduplication contract used below.

## Collect from installed copies

Run only when the user explicitly asks from the canonical AI Dev Workflow distribution checkout and supplies each installation root. This is observation intake, not project/Git integration. Never discover installations by crawling parent directories or drives.

An installation input may be a project/worktree root or its direct `.ai/maintenance/observations/` directory. For a project root, resolve only that exact child directory. Read only direct `OBS-*.yaml` files; never import project code, Knowledge, lanes, Tasks, Integration artifacts, Evals, update state, backups, full chats, or logs. Input files are read-only.

Use two passes:

1. Inventory and validate every candidate's YAML shape, ID, fingerprint, timestamps, occurrence count, and `source_records` before writing anything.
2. Import into the canonical `.ai/maintenance/observations/` only when the full inventory is safe. A malformed candidate is a reported conflict, not a partial import.

Collection rules:

- Expand a legacy record to one synthesized source record in memory.
- A source-record ID already stored with the same or newer `updated_at` and occurrence count is `skipped`.
- A newer version of a stored source record contributes only the positive occurrence delta and materially new evidence; then replace its stored `updated_at` and count.
- The same source-record ID with changed content but no monotonic timestamp/count evidence is `conflicts`; do not silently choose a copy.
- A source-record ID associated with another fingerprint is `conflicts`; never overwrite or guess.
- Different source-record IDs with the same open fingerprint merge into the existing canonical record. If none exists, copy the first valid record as canonical.
- New records use the four-part `stage | symptom_class | provider_scope | contract_or_route` fingerprint. A legacy three-part record uses `contract_or_route=unknown` and does not merge with a four-part record unless triage proves the same root contract/route.
- Deduplicate evidence by the exact tuple `kind | ref | note`. Set canonical `occurrences` to the sum of its unique `source_records` counts and retain every source-record entry.
- Do not copy a redundant same-fingerprint file after its data is merged. If duplicate canonical files already exist, consolidate them only after the merged record validates; leave every supplied source untouched.
- Different fingerprints remain separate observations. Collection never triages, changes Core, creates a release, or changes project/lane state.

Collection must be safe to rerun with the same sources and produce zero new counts. Report exactly:

```text
OBSERVATION_COLLECTION scanned=<n> new=<n> merged=<n> skipped=<n> conflicts=<n>
destination=<canonical observations path> next=<triage|resolve_conflicts|none>
```

## BUILD_RELEASE_COPY: update the separate distributable `.ai`

Run only when the user explicitly requests `BUILD_RELEASE_COPY` from the separate canonical AI Dev Workflow distribution checkout and supplies every installed project/worktree root. The supplied installations retain their complete project state; the canonical checkout is the independent distribution copy. This single request authorizes bounded observation collection, candidate comparison, triage, accepted generic Core edits, one release-version/Changelog update, provisional affected-case checks, and development-mode distribution validation. It does not authorize a Git commit, completed release Eval, push, remote change, supplied-project edit/cleanup/deletion, or full installed `.ai` copy.

The canonical distribution checkout's `.ai` is the output installation copy. Do not create a nested repository, sanitize an installation in place, or treat an installed project as the release destination. Before writing, verify the canonical checkout and inventory its existing changes. Stop on unrelated or unexplained Core dirt instead of mixing releases.

Every supplied installation is read-only and lossless. Record its revision/status before inspection and verify that the command made no writes before reporting success. Use two evidence channels:

1. collect direct `OBS-*.yaml` records using the rules above; and
2. compare only common paths covered by the `managed` section of the canonical `.ai/maintenance/managed-paths.yaml`.

An installed managed-file difference is an untrusted candidate, not authoritative content. Never bulk-copy or mirror it. Confirm its intent from an Observation, user report, current canonical contract, or a minimal diff; then reapply only the generic change onto the latest canonical file. An older installed version never overwrites a newer canonical rule. Ambiguous, conflicting, project-specific, or unsupported differences become `needs_evidence` or a user Decision Brief.

Never read for reverse synchronization or copy into the canonical distribution:

- `.ai/shared/PROJECT.md`, `.ai/shared/SYSTEM_ARCHITECTURE.md`, or project Knowledge except the managed Knowledge README;
- any runtime Lane other than the canonical `_template`, including Architecture, Tasks, Builds, Reviews, state, and knowledge deltas;
- Integration queue/items, requests, reviews, project `.ai/evals/runs`, local update state, backups, staging, or full chats/logs;
- production code, documents, credentials, secrets, absolute project paths, project names, IDs, or user data.

Canonical release metadata is rebuilt in the distribution checkout; never reverse-copy installed `release.yaml`, `managed-paths.yaml`, `CHANGELOG.md`, project Eval runs, or `update-state.yaml`. Raw collected observations are local intake evidence and are not part of the published installation copy. Accepted changes are represented by the generic Core diff, Changelog, and a sanitized source-only Eval under `evals/runs/`.

For one accepted release batch:

1. retain the uninitialized project/Knowledge/Integration scaffold and `_template` as the only Lane;
2. apply the smallest generic change without weakening correctness, safety, explanation, or verification;
3. add/update directly affected regression cases;
4. bump the canonical version exactly once and update Changelog; do not rewrite historical Eval versions;
5. run affected cases provisionally without creating a completed Eval record;
6. run `tools/validate-workflow.ps1` without `-RequireReleaseEvidence` from the distribution root;
7. leave all source changes uncommitted for human review and report that an immutable source commit plus an independent post-commit Workflow Review are required before final Eval.

Do not let this authoring session self-approve the release. A provisional contract trace may guide development, but only the fresh-session clean-HEAD Workflow Review embedded by `FINALIZE_RELEASE_EVAL` is release evidence.

If no candidate is accepted, do not bump the version or create release artifacts. Report exactly:

```text
BUILD_RELEASE_COPY RESULT=<source_commit_required|no_change|blocked> version=<version>
sources=<n> observations=<n> common_candidates=<n> accepted=<n>
source_projects_unchanged=<yes|no|unknown> excluded_project_state=<yes> validation=<pass|not_run|failed>
workflow_review=<required_after_source_commit|not_run>
artifacts=<paths|none> next=<review_and_commit_source|none|resolve_conflict|user_decision>
```

## FINALIZE_RELEASE_EVAL: bind evidence to the source commit

Run only in a fresh session after the user explicitly says the versioned source changes were committed and asks to finalize that release Eval. The finalizing session must not have authored those source changes. This request authorizes one independent clean-HEAD Workflow Review, affected-case execution, one sanitized completed Eval record under source-only `evals/runs/` containing that review, and staging only that Eval record so validation can prove it will be tracked. It still does not authorize a source rewrite, commit, Push, tag, or remote mutation.

1. Require a clean source tree before the Eval record is created and verify `HEAD` contains the intended `release.yaml` version and Changelog entry.
2. Read `maintenance/WORKFLOW_REVIEW.md` and run `mode=changed` against that immutable `HEAD` in this independent session. Stop without creating an Eval if the review is blocked, has any P1/applicable FAIL, or cannot justify a deferred P2. A Workflow PASS may still report release `not_ready` solely because the Eval record has not been created yet.
3. Record full `source_revision=HEAD` and `source_tree=HEAD^{tree}`. The source commit must not already contain the new Eval record.
4. Set `eval_type: source_regression`, run the affected canonical regression cases, and complete every Core Result and Targeted Regressions row with evidence. Do not run or imply baseline/A/B, token, speed, or model-parity comparison.
5. Copy the complete ten-lens review, findings, and bounded self-check into the Eval's `## Workflow Review` section. Set front matter `workflow_review_result: pass`, `workflow_review_mode: changed`, `workflow_review_independence: independent_session`, and truthful `workflow_review_self_check: pass | corrected`; do not summarize away corrections or deferred P2 evidence.
6. Set `status: completed`, truthful `result`, UTC `completed_at`, and `quality_floor`; failed results remain records but cannot release.
7. Write the record to `evals/runs/`, stage only that record, inspect the staged path/diff, and run `tools/validate-workflow.ps1 -RequireReleaseEvidence` plus `tools/test-validation.ps1`.
8. Leave the Eval staged for human review and its separate record commit.

```text
FINALIZE_RELEASE_EVAL RESULT=<eval_commit_required|failed|blocked> version=<version>
source_revision=<commit> source_tree=<tree> result=<pass|fail|none>
workflow_review=<pass|changes_required|blocked|not_run> independence=<independent_session|reduced_assurance|unknown>
eval=<staged source-only path|none> validation=<pass|failed|not_run>
next=<review_and_commit_eval|repair_source|none>
```

## Triage and release

Run only on explicit maintenance request. Batch related pending observations, verify the root cause against current Core and source Evals, and classify each `accepted | rejected | needs_evidence`. An accepted change requires:

- a minimal rule/contract change tied to evidence;
- a regression case that fails before or is otherwise demonstrably relevant;
- no quality-floor regression and no project-state overwrite;
- version/changelog update; and
- a migration only when a preserved schema must change.

Never release solely from popularity, one unsupported observation, or lower token count that loses correctness, safety, verification, or user understanding.
