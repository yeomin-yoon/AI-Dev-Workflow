# Artifact Authority

No single artifact is authoritative for every fact.

| Fact | Authority |
|---|---|
| user goal | latest explicit request / approved spec |
| scope and completion | approved task |
| intended structure | approved architecture/ADR |
| current implementation | live source/config/assets/schema |
| observed behavior | build/test/runtime evidence |
| workflow state | lane `state.yaml` |
| discovery | sourced knowledge index |
| project terminology | approved project docs/architecture/source usage; glossary is an index |
| current external fact | dated official/primary source; inference remains labeled |
| Workflow improvement candidate | observation evidence; non-authoritative until triage + Eval + release |
| installed Workflow version/update state | `.ai/maintenance/release.yaml` + preserved `update-state.yaml` |
| change explanation | Review Result derived from its reviewed revision; orientation only |
| parallel Lane boundary/base | approved System/Lane Architecture + Git; `PARALLEL_START` is a derived executable handoff |
| Integration candidate identity | Build/Review base + reviewed commit/tree, metadata-only handoff commit, and Git ancestry/diffs |
| worktree session return/next start | referenced lane state/current artifacts + Git/worktree state; `RETURN_TO_MAIN` and `NEXT_SESSION` are derived executable handoffs |
| history | Git |

Knowledge status: `verified | inferred | stale | unknown | conflict`.

## Conflict actions

- Knowledge vs source: use source; mark knowledge `stale/conflict`.
- Architecture vs source: report drift; route implementation error to Builder or changed intent to Architect.
- Task vs architecture: do not build; Architect resolves it.
- Test vs requirement: do not PASS from the test alone; raise `verification`.
- Document vs document: compare approval, scope, owner, ADR, and project evidence; date alone does not decide.

Artifact states:

```text
Architecture/Task/Integration-request approval: draft/proposed → approved | rejected → superseded
implementation evidence: Build candidate → Review pass | fail | blocked
```

Record a source revision on architecture, task, build, review, and knowledge manifests. If revisions differ, inspect relevant changed paths before deciding whether context remains valid.
