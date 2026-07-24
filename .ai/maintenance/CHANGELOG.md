# Workflow Changelog

## manual-v1.21 — 2026-07-25

- Added one explicit `CLEAN_RELEASE` command that turns supplied installed-project evidence into the latest clean canonical `.ai` without reverse-copying project state.
- Treats installed common-file differences as untrusted candidates, rebuilds accepted changes against the latest canonical Core, and keeps release metadata and sanitized Evals source-owned.
- Keeps publication human-controlled: the command validates a ready-to-publish source but never commits, pushes, changes remotes, or edits supplied projects.

## manual-v1.20 — 2026-07-25

- Made `release.yaml` the single current-version authority and changed the reusable Scorecard to an unversioned template while preserving historical Eval versions.
- Added a source-only, read-only validation command and GitHub check for version consistency, required files, local references, and Markdown fence balance.
- Clarified that installation copies only `.ai`; source Git/CI/tools stay in the GitHub repository and installed projects use their own Git history.

## manual-v1.19 — 2026-07-25

- Clarified that Bootstrap prompts are pasted as the first user message in a newly created AI session, not as a System Prompt or terminal command.
- Added host-native text-search fallback order so a missing POSIX or preferred executable never becomes a false blocker.
- Reduced the copied `RETURN_TO_MAIN` instruction to minimum reconstruction locators and added deterministic path → committed Git → unique-state → User Action recovery.
- Made Main Front Desk preserve and checkpoint deferred `pending_reviews` without forcing Knowledge sync after every Lane.

## manual-v1.18 — 2026-07-25

- Made compact `main` Work the sole worktree Front Desk and Integration executor, including when worker Lanes use strict fixed-role topology.
- Added sealed candidate identity: one Task-scoped code commit, exact base/candidate/tree Review, and one metadata-only Lane handoff commit.
- Split Task, workflow, unrelated, and Observation dirt so exact committed candidates can integrate without declaring a dirty worktree removable.
- Added return-card topology/language/tool reconstruction metadata and moved handoff/User Action/close schemas into on-demand contracts.
- Added Lane-only `PREPARE_DELTA`, per-merge main before/after provenance, exact Integration review ranges, and golden lifecycle coverage.
- Added metadata-only main Review and canonical Knowledge checkpoints so sequential integrations never stack on dirty tracking state.
- Removed default session-title mutation and reduced duplicated Bootstrap instructions.
- Kept preserved schemas compatible: older Reviews remain history, but a pre-v1.18 non-main candidate without commit/tree/handoff evidence must be re-reviewed and sealed before Integration.

## manual-v1.17 — 2026-07-25

- Made the existing main Work/Architect session the worktree-mode Front Desk without introducing another role or autonomous orchestrator.
- Added concrete `RETURN_TO_MAIN` and `NEXT_SESSION` cards so every closed non-main session returns through main and users no longer retain or reconstruct Lane prompts.
- Kept direct handoffs between already-open Work/Reviewer sessions inside one Lane while centralizing actual session replacement and cross-worktree movement.
- Folded a Review-PASS return into the bounded one-candidate Integration authorization and added Git/Observation/worktree-removal safety checks at Front Desk intake.

## manual-v1.16 — 2026-07-25

- Pinned every bootstrapped session to one checkout and Lane; moving to another worktree/Lane now requires a new session and a target-specific prompt.
- Made multi-Lane handoffs identify the target Lane and absolute worktree instead of relying on ambiguous session labels.
- Defined session close as a durable checkpoint, separated conditional/manual Observation capture from close itself, and documented what close never performs implicitly.
- Turned approved integration order into an explicit one-candidate main Work loop with independent main Review, actionable Git fallbacks, and no repeated approval when the boundary is unchanged.

## manual-v1.15 — 2026-07-25

- Fixed replacement-session guidance so non-main Lanes reuse their own Parallel Start prompts instead of accidentally bootstrapping `main`.
- Made compact Work+Reviewer the explicit default for new parallel Lanes and added strict four-role cards only on explicit request.
- Reused the already approved integration order and removed a redundant approval; a new decision is requested only when evidence changes the order/boundary.
- Clarified that all sessions attached to an updated checkout must restart, defined Worktree for new users, removed provider-specific title wording, and reduced duplicated public guidance.

## manual-v1.14 — 2026-07-25

- Added an explicit Architect-owned `PARALLEL_START` contract for requested multi-worktree development.
- Made main generate concrete per-Lane worktree commands, Work/Reviewer Bootstrap prompts, and first requests so users never hand-edit `lane=main`.
- Required one approved committed partition before worktree creation and added actionable recovery when that baseline is not ready.
- Made additional Lane initialization reuse the pinned canonical Knowledge and validate only its approved boundary instead of triggering redundant broad rebuilds.

## manual-v1.13 — 2026-07-25

- Made `main` the explicit standard lane across copy-paste prompts, providers, sessions, and ordinary worktrees; non-main lanes now require a deliberate user opt-in.
- Added a hidden-by-default user guide for bootstrapping an optional additional lane without turning it into normal setup work.
- Added explicit, source-scoped collection of Workflow observations from multiple installed projects/worktrees.
- Made collection rerunnable through source-record provenance, exact-fingerprint grouping, evidence deduplication, and conflict reporting without importing project state or changing Core.
- Replaced new branch-local Eval sequence IDs with collision-resistant UTC/provider/slug IDs; legacy Eval records remain valid.

## manual-v1.12 — 2026-07-25

- Made `role × lane` the only session identity, restored the active Task from durable state, and prevented Bootstrap-only session replacement from auto-executing it.
- Kept pending user decisions/evidence assigned to the responsible Architect or Reviewer instead of inventing `user`/`integration` roles.
- Removed redundant same-session handoffs while retaining exact cross-session instructions and actionable user gates.
- Made Task and Integration Request status approval-only, materialized future Tasks just in time, and kept execution in state/Build/Review.
- Fixed Builder false blockers for approved structural work and made Review/Knowledge routing evidence-dependent.
- Separated production lane path rules from role-owned `.ai` artifacts and defined the System Architecture writer.
- Standardized Knowledge revision keys, narrowed canonical writer scope, and added a preserving migration.
- Added a compact pre-write dirty baseline so Review can distinguish user changes from the current Task.
- Reduced Eval ceremony by separating a core scorecard from targeted regression cases.

## manual-v1.11 — 2026-07-25

- Added evidence-gated automatic and always-available manual Workflow observation capture.
- Added deduplication and noise exclusions for ordinary project defects and corrected one-off model slips.
- Added managed/preserved path separation, version metadata, safe update checks, backups, migrations, validation, and rollback.
- Added Eval coverage for observation precision and project-state-preserving updates.

## manual-v1.10 — 2026-07-25

- Added a simplicity ladder, sourced project glossary, task-local skill boundaries, and evidence-bounded current research.
