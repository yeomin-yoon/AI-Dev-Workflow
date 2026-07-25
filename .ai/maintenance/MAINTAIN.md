# Workflow Observation Maintenance

Read only for explicit observation capture or after a Bootstrap automatic trigger. This installed-project procedure is not a project role and never changes lane state. Observation collection, Core release work, and release Eval finalization exist only in the canonical distribution checkout under `maintenance/RELEASE.md`; they are intentionally not installed with `.ai`.

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
