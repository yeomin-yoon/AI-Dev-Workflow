# Workflow Maintenance

Read only for explicit observation capture/collection/triage/release work or after a Bootstrap automatic trigger. Maintenance is not a project role and never changes lane state.

## Capture modes

### Manual

When the user asks to record a problem, always create or deduplicate a pending observation. Use current artifacts and concise user evidence; do not require proof or a questionnaire. Mark unsupported fields `unknown` and `confidence: low`. Manual capture may record a suspected issue that triage later rejects.

### Automatic

Capture only when all are true:

1. concrete evidence exists in an artifact, state/diff, Eval, command result, or user correction;
2. the symptom concerns Workflow routing, role/gate/scope enforcement, state/artifact contract, required user-language actionability, provider compatibility, or Eval quality floor;
3. at least one Bootstrap automatic trigger is met; and
4. the issue affected an artifact, handoff, user action, retry, or accepted-result quality.

Do not auto-capture:

- production code bugs, normal Review findings, or failed project tests;
- a new architecture/product decision or the user changing intent;
- an expected unavailable tool already routed correctly;
- evidence-driven context expansion that follows the Task budget policy;
- a one-off model slip corrected before it affected an artifact/handoff;
- stylistic preference without measurable impact;
- a duplicate open fingerprint without materially new evidence.

When uncertain, do not auto-record. The manual path covers missed cases.

## Deduplicate

Search only pending/accepted observation headers and `fingerprint`. A fingerprint is the stable tuple `stage | symptom_class | provider_scope`; it excludes wording, Task ID, and timestamps.

- Same open fingerprint + materially new evidence: append one evidence item, increment `occurrences`, update `updated_at`, and update the matching local `source_records` entry.
- Same fingerprint without new evidence: do nothing.
- Different root symptom: create a new file.

## Record

Path: `.ai/maintenance/observations/OBS-<YYYYMMDDTHHMMSSfffZ>-<provider>-<short-slug>.yaml` using a filename-safe UTC timestamp.

```yaml
schema_version: 1
id: OBS-<YYYYMMDDTHHMMSSfffZ>-<provider>-<short-slug>
created_at: <ISO-8601>
updated_at: <ISO-8601>
source: <manual|automatic>
workflow_version: <version>
provider: <codex|claude|gemini|other|unknown>
role: <work|architect|builder|reviewer|knowledge_maintainer|operations|unknown>
lane: <lane|unknown>
trigger: <user_report|false_blocker|invalid_route_state|missing_actionability|redundant_gate|avoidable_context|workflow_correction|recurring_recovery|provider_contract|eval_floor>
fingerprint: <stage | symptom_class | provider_scope>
summary: <one factual sentence>
impact: <retry, delay, bad decision, token cost, quality risk, or unknown>
evidence:
  - kind: <artifact|state|diff|eval|command|user_report>
    ref: <path/symbol/result or user_report>
    note: <minimum useful fact>
occurrences: 1
classification: <workflow|provider|documentation|token|eval|migration|unknown>
confidence: <low|medium|high>
status: pending
related: []
source_records:
  - id: <same observation id>
    provider: <same provider>
    workflow_version: <same workflow_version>
    updated_at: <same updated_at>
    occurrences: 1
```

`source_records` makes collection from several installed copies idempotent while retaining provider/version provenance. A legacy observation without it is valid; synthesize one source record from its top-level `id`, `provider`, `workflow_version`, `updated_at`, and `occurrences`.

Never store secrets, full chat transcripts, full logs, or copied source. Capture does not edit Core, update state, create a blocker, or interrupt the current route.

If written or materially updated, add one chat line:

```text
WORKFLOW_OBSERVATION=<path> source=<manual|automatic>
```

Otherwise say nothing about capture during ordinary work. A `RETURN_TO_MAIN` card may use `observation=none` as a compact close-safety status; this does not claim that capture ran beyond the normal trigger or create a record.

## Collect from installed copies

Run only when the user explicitly asks from the canonical AI Dev Workflow source checkout and supplies each source root. This is observation intake, not project/Git integration. Never discover sources by crawling parent directories or drives.

A source may be an installed project/worktree root or its direct `.ai/maintenance/observations/` directory. For a project root, resolve only that exact child directory. Read only direct `OBS-*.yaml` files; never import project code, Knowledge, lanes, Tasks, Integration artifacts, Evals, update state, backups, full chats, or logs. Source files are read-only.

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
- Deduplicate evidence by the exact tuple `kind | ref | note`. Set canonical `occurrences` to the sum of its unique `source_records` counts and retain every source-record entry.
- Do not copy a redundant same-fingerprint file after its data is merged. If duplicate canonical files already exist, consolidate them only after the merged record validates; leave every supplied source untouched.
- Different fingerprints remain separate observations. Collection never triages, changes Core, creates a release, or changes project/lane state.

Collection must be safe to rerun with the same sources and produce zero new counts. Report exactly:

```text
OBSERVATION_COLLECTION scanned=<n> new=<n> merged=<n> skipped=<n> conflicts=<n>
destination=<canonical observations path> next=<triage|resolve_conflicts|none>
```

## BUILD_RELEASE_COPY: update the separate distributable `.ai`

Run only when the user explicitly requests `BUILD_RELEASE_COPY` from the separate canonical AI Dev Workflow source checkout and supplies every installed project/worktree root. The supplied installations retain their complete project state; the canonical checkout is the independent GitHub distribution copy. This single request authorizes bounded observation collection, candidate comparison, triage, accepted generic Core edits, one release-version/Changelog update, directly affected Eval work, and source validation. It does not authorize a Git commit, push, remote change, supplied-project edit/cleanup/deletion, or full installed `.ai` copy.

The canonical source checkout's `.ai` is the output copy. Do not create a nested repository, sanitize an installation in place, or treat an installed project as the release destination. A third generated copy is unnecessary and would add another drift boundary. Before writing, verify the canonical checkout and inventory its existing changes. Stop on unrelated or unexplained Core dirt instead of mixing releases.

Every supplied installation is read-only and lossless. Record its revision/status before inspection and verify that the command made no writes before reporting success. Use two evidence channels:

1. collect direct `OBS-*.yaml` records using the rules above; and
2. compare only common paths covered by the `managed` section of the canonical `.ai/maintenance/managed-paths.yaml`.

An installed managed-file difference is an untrusted candidate, not authoritative content. Never bulk-copy or mirror it. Confirm its intent from an Observation, user report, current canonical contract, or a minimal diff; then reapply only the generic change onto the latest canonical file. An older installed version never overwrites a newer canonical rule. Ambiguous, conflicting, project-specific, or unsupported differences become `needs_evidence` or a user Decision Brief.

Never read for reverse synchronization or copy into the canonical source:

- `.ai/shared/PROJECT.md`, `.ai/shared/SYSTEM_ARCHITECTURE.md`, or project Knowledge except the managed Knowledge README;
- any runtime Lane other than the canonical `_template`, including Architecture, Tasks, Builds, Reviews, state, and knowledge deltas;
- Integration queue/items, requests, reviews, project Eval runs, local update state, backups, staging, or full chats/logs;
- production code, documents, credentials, secrets, absolute project paths, project names, IDs, or user data.

Canonical release metadata is rebuilt in the source; never reverse-copy installed `release.yaml`, `managed-paths.yaml`, `CHANGELOG.md`, Eval runs, or `update-state.yaml`. Raw collected observations are local intake evidence and are not part of the public clean distribution. Accepted changes are represented by the generic Core diff, Changelog, and a sanitized canonical Eval.

For one accepted release batch:

1. retain the uninitialized project/Knowledge/Integration scaffold and `_template` as the only Lane;
2. apply the smallest generic change without weakening correctness, safety, explanation, or verification;
3. add/update directly affected regression cases;
4. bump the canonical version exactly once and update Changelog; do not rewrite historical Eval versions;
5. create a sanitized Eval record with no project-specific content;
6. run `tools/validate-workflow.ps1` from the source root and require PASS; and
7. leave all changes uncommitted for human review and GitHub publication.

If no candidate is accepted, do not bump the version or create release artifacts. Report exactly:

```text
BUILD_RELEASE_COPY RESULT=<ready_to_publish|no_change|blocked> version=<version>
sources=<n> observations=<n> common_candidates=<n> accepted=<n>
source_projects_unchanged=<yes|no|unknown> excluded_project_state=<yes> validation=<pass|not_run|failed>
artifacts=<paths|none> next=<review_and_commit|none|resolve_conflict|user_decision>
```

## Triage and release

Run only on explicit maintenance request. Batch related pending observations, verify the root cause against current Core and Evals, and classify each `accepted | rejected | needs_evidence`. An accepted change requires:

- a minimal rule/contract change tied to evidence;
- a regression case that fails before or is otherwise demonstrably relevant;
- no quality-floor regression and no project-state overwrite;
- version/changelog update; and
- a migration only when a preserved schema must change.

Never release solely from popularity, one unsupported observation, or lower token count that loses correctness, safety, verification, or user understanding.
