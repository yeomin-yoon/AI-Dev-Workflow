# Workflow Observation Maintenance

Read only when the user explicitly asks to preserve a Workflow problem inside the installed project. This installed-project procedure is optional, is not a project role, and never changes lane state. Ordinary roles do not open it or create records automatically. A user may instead describe or paste the inconvenience directly in the canonical distribution checkout without creating a local record first. Observation collection, Core release work, and release Eval finalization exist only there under `maintenance/RELEASE.md`; they are intentionally not installed with `.ai`.

## Manual capture

When the user asks to record a problem, always create or deduplicate a pending observation. Use current artifacts and concise user evidence; do not require proof or a questionnaire. Mark unsupported fields `unknown` and `confidence: low`. Manual capture may record a suspected issue that triage later rejects.

## Deduplicate

Search only pending/accepted observation headers and `fingerprint`. A new fingerprint is the stable tuple `stage | symptom_class | provider_scope | contract_or_route`; it excludes wording, Task ID, and timestamps. `contract_or_route` is the owning contract/path or route name that distinguishes the same visible symptom from a different root cause.

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
source: manual
workflow_version: <version>
provider: <codex|claude|gemini|other|unknown>
role: <work|architect|builder|reviewer|knowledge_maintainer|operations|unknown>
lane: <lane|unknown>
trigger: <user_report|false_blocker|invalid_route_state|missing_actionability|redundant_gate|avoidable_context|workflow_correction|recurring_recovery|provider_contract|eval_floor>
contract_or_route: <owning contract/path or route name|unknown>
fingerprint: <stage | symptom_class | provider_scope | contract_or_route>
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

`source_records` makes collection from several installed copies idempotent while retaining provider/version provenance. Historical records with `source: automatic` remain readable but are never created by this version. A legacy three-part fingerprint remains readable and uses `contract_or_route=unknown`; do not merge it with a four-part record unless triage proves the root contract/route is the same. A legacy observation without `source_records` is valid; synthesize one source record from its top-level `id`, `provider`, `workflow_version`, `updated_at`, and `occurrences`.

Never store secrets, full chat transcripts, full logs, or copied source. Capture does not edit Core, update state, create a blocker, or interrupt the current route.

If written or materially updated, add one chat line:

```text
WORKFLOW_OBSERVATION=<path> source=manual
```

Otherwise say nothing about capture during ordinary work. A `RETURN_TO_MAIN` card may use `observation=none` as a compact close-safety status; this reports only that no local Observation path is present and never runs capture.
