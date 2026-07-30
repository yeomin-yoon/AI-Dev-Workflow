# Workflow Changelog

## manual-v1.2 — 2026-07-30

- Added optional requirement baselines that pin only applicable PRD/spec/GDD sections and revisions without requiring a form or copying whole documents.
- Classified requirement drift as implementation deviation, approved intent change, or unclear authority so code and specifications are never silently synchronized.
- Added a deterministic requirement-drift fixture and negative validation cases covering routing, Task supersession, and source-only Knowledge indexing.
- Kept requirement-drift status inside Knowledge-owned entries and synchronized the new requirement baseline with the fresh-Lane Architecture scaffold.
- Clarified that Workflow rules, approvals, Git, and Worktrees are process controls rather than OS security boundaries, with risk-scaled containment, actionable context/user recovery, and an inverse guard that keeps proven project-local checks on the normal path.
- Added evidence-triggered re-scope for directionally wrong candidates and bounded batching of related input without widening Task scope or adding a new gate.
- Separated external update-candidate read containment from target `.ai` write containment, rejected symlink/reparse escapes at both roots, made the Golden Core trigger catalog single-source, and removed an unmeasured time implication from the README example.
- Made context retrieval evidence-based: names and similarity produce candidates only, while targeted source checks establish scope, freshness, authority, schema, and runtime applicability before Knowledge or Architect relies on them.
- Allowed bounded restores from project-declared dependency sources without weakening lifecycle-script execution controls, centralized Review PASS conditions, documented Knowledge approval-field compatibility, and kept normative Architecture rules outside generated artifact prose.
- Reframed the README around the intended user experience—start briefly, decide with understanding, learn through real work, build small, and verify with evidence—while keeping `.ai/WORKFLOW.md#design-principles` as the single canonical source.
- Bound Workflow Apply to the exact candidate commit/tree and canonical input manifest recorded by Check, persisted exact new-path approvals, and made rollback restore both present and absent pre-state without deleting concurrent work by assumption.
- Added an optional cross-lane requirement baseline to System Architecture so shared-contract requirement changes version the system boundary and supersede every affected Lane Task before Integration.
- Made README philosophy completeness, Update transaction oracles, cross-lane requirement routing, and ASCII-only PowerShell validator sources deterministic regression checks.
- Treated tacit feedback such as "something feels off" as a valid design seed: Architect now performs one bounded evidence-based diagnosis before clarification, surfaces non-obvious possibilities without expanding scope, and resolves the result into observable acceptance criteria before Build.
- Closed `ready_to_build/blocked` and `building/blocked` repair/resume paths, including explicit disposition of interrupted single-main Task-attributed changes before a replacement Build.
- Replaced free-form installed Update validation claims with a seven-row observation/evidence matrix and unified rollback proof under one transaction manifest with immutable pre-state and completed mutation records.
- Corrected the public Workflow Review lens summary, enforced a fresh non-authoring release-finalizer session, and aligned the top-level Update summary with its independent candidate-read and install-write roots.
- Clarified that green checks cannot excuse weakened test oracles, invariant bypasses, or concrete maintainability pressure; preferred bounded vertical slices and conditional program-shape guidance without adding a new artifact or gate; and kept consequential code ownership human-centered through focused inspection paths.
- Hardened canonical release evidence so every named source-regression case must pass and every counted P2 carries a detailed finding plus deferred follow-up proof.
- Completed pre-Review, changed-byte Build, and Task-Review integration recovery paths without reusing stale candidates or verdicts, and made Build Baseline preserve unrelated, inherited, and unknown dirty-path attribution across attempts.
- Made Workflow Apply transactions discoverable after session interruption through a durable manifest pointer and required all seven installed checks to return evidenced `pass|fail` results rather than `not_applicable`.
- Let release finalization select and faithfully record `changed` or `full` Workflow Review mode, and defined the narrow, disclosed, non-release reduced-assurance exception for ordinary same-session Task Review.
- Made the canonical distribution source self-describing while requiring user confirmation before installed source metadata can seed an update Check, and exposed Change Brief in the public glossary.

## manual-v1.1 — 2026-07-26

- Made request intake adapt to the user's level of detail: preserve explicit intent, derive known project context, and ask only consequential user-owned unknowns without a mandatory prompt form.
- Added evidence-based code-quality rules for intent, invariants, ownership/lifetime, responsibility, extensibility, and performance while rejecting ceremonial abstraction and generic pattern enforcement.
- Added sourced team/project-rule discovery and precedence so repository conventions govern their scope, inferred patterns remain labeled, and conflicts are routed instead of guessed.
- Completed Review repair/resume and terminal no-Knowledge state transitions so blocked or finished work has an explicit next state.
- Added repository trust, secret-handling, and script/hook execution boundaries for new team projects.
- Constrained Workflow updates to the resolved project `.ai`, including preserved-path reclassification checks, new-managed-path approval, installed/source validation profiles, and verified rollback restoration.
- Made every role load the contract for the artifact it writes and simplified single-main candidate fingerprints to a reproducible Task-path content manifest with a real Git baseline.
- Moved optional worktree sealing/Integration detail out of normal role hot paths and defined fresh-main continuation for repeated Tasks in one Lane.
- Added installable MIT notice, local ignored update-state with a tracked regeneration template, single-source Knowledge rule projections, and root-cause-aware Observation fingerprints.
- Added deterministic Golden Core Behavior fixtures plus targeted regression cases for request detail, evidence-based review, project-rule conflicts, trust, state repair, update safety, and Lane continuation.
- Added a source-only, read-only Workflow Review that audits user, design, practical, maintenance, efficiency, and security quality without adding a runtime role or installed-project cost.
- Closed Integration-blocked repair/resume paths, bound canonical release Workflow Review to an independent clean-commit Eval, and made single-main fingerprint header/mode encoding deterministic.
- Added one bounded adversarial self-check to Workflow Review so it catches its own omissions, false positives, evidence/release-boundary mistakes, and inconsistent counts before final reporting.
- Kept self-check criteria stable by default: external ideas are considered only on explicit refresh or demonstrated review failure, must prove local applicability and regression value, and validly end with `no_change` when nothing merits adoption.
- Made the eligible release-evidence fixture derive its version from the candidate release so version bumps remain self-validating.
- Added a canonical Task Quality Gate that distinguishes READY, SPLIT, MERGE, and BLOCKED from observable outcomes, atomic scope, verification, dependencies, and handoff value without adding another Agent or user gate.
- Bound release eligibility to the source commit's complete distribution inventory so a locally preserved but untracked scaffold file cannot disappear from a fresh clone unnoticed.
- Separated canonical `source_regression` release evidence from optional `end_to_end`/`fixed_contract` comparisons, pinned the no-Workflow baseline to A's exact execution configuration, and required observed or explicitly user-declared run metadata instead of model self-identification.
- Strengthened README onboarding with a stable audience/problem statement, explicit Work/Reviewer window separation, a bounded walkthrough, and a source-only cold-reader Quality Gate without adding an installed-project role or runtime cost.
- Reduced the visible command surface by routing Review follow-up through generated `DO_NEXT`, consolidating document/code/Git Knowledge refresh into one change signal, and removing the obsolete session-close alias.
- Renamed the time-implying README entry to `빠른 시작` and added a targeted diagnostic when the canonical distribution loses its intentionally force-tracked, installation-ignored update-state scaffold.

## manual-v1.0 — 2026-07-25

- First public release of the file-backed, model-agnostic AI development Workflow.
- Added durable project Knowledge, Architecture, Task, Build, Review, State, and Integration contracts so sessions remain replaceable workers instead of memory stores.
- Added a compact default of one Work session plus one independent Reviewer, with strict four-role sessions available on demand.
- Added small-Task planning, bounded context loading, evidence-based Review, actionable user gates, and risk-scaled explanations.
- Added optional Lane/Worktree parallel development with a `main` Front Desk, sealed candidates, exact Integration review, and safe session replacement.
- Added project-safe Workflow updates, manual and evidence-gated automatic Observation capture, and source/install separation.
- Added reusable Eval contracts, release-evidence validation, cross-platform CI, negative fixtures, and distribution-integrity checks.
- Defined efficiency, model parity, and natural learning as measurable goals rather than guaranteed outcomes.
