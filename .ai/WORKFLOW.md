# Workflow Runtime Reference

Read this only for policy conflicts, recovery, or integration. Normal runs use `BOOTSTRAP.md`; operational exception steps are in `.ai/reference/OPERATIONS.md`.

## Design principles

This is the single canonical statement of why the Workflow is designed as it is. These principles guide Workflow changes but never override approved project intent, artifact authority, or verified source/runtime evidence.

1. **Files and Git over chat memory.** Sessions are replaceable workers; durable state, decisions, evidence, and history live in their owning artifacts and Git.
2. **Think big, build small.** User and Architect reason about Feature-scale intent and structure; Builder produces at most one small, approved, reviewable Task candidate at a time.
3. **Input depth follows the user.** A request may be a short seed, a detailed specification, referenced documents, or a tacit/evaluative signal such as "something feels off." Preserve every explicit goal, rationale, environment, priority, constraint, acceptance condition, and requested deliverable; derive available context from authoritative project files; ask only for missing user-owned intent that materially changes scope, design, risk, or acceptance. Evaluative or tacit seeds are valid problem signals, not failed requirements: before asking the user to diagnose the system, use targeted evidence to translate the signal into an observable symptom, bounded causal hypotheses with uncertainty, the most likely explanation, and the smallest discriminating probe or proposed improvement. Surface a relevant non-obvious possibility without silently adding it to scope, and turn a sufficiently resolved diagnosis into observable acceptance criteria before Build. Never require a form or re-ask a known fact. Durable product/requirements/specification sources are optional and, when used, are referenced by exact requirement section and revision rather than copied wholesale.
4. **Context quality over context volume.** Start from state, artifact pointers, paths, symbols, and diffs. Expand context only when evidence is missing; never preload the project or every Workflow document.
5. **Evidence over confidence.** Source, approved intent, deterministic checks, runtime observations, and exact revisions decide acceptance. Agent fluency or assurance is not evidence. A green check is evidence, not proof that its oracle, architecture, or long-term maintainability remained sound.
6. **Independent Review over self-approval.** The author of a candidate cannot silently grant it an independent PASS. Findings route to the role that owns the defect without preference-driven redesign.
7. **Informed user judgment for consequential decisions.** AI makes reversible local choices and routine verified operations without interruption. A user Gate exists only when the user has a real choice between materially different user-owned outcomes, scope, public compatibility, irreversible/external effects, cost/risk, or mandatory human acceptance. Before that Gate, expose evidence, concrete observable consequences, recommendation, deferral/rejection consequence, uncertainty, and reconsideration conditions in language the user can use; an unexplained or effectively unavoidable approval is ceremony, not valid control. Explanations are intended to support natural learning without quizzes or ceremony; they do not guarantee skill growth. Independent AI Review reduces review burden but never transfers code ownership or proves long-term maintainability; consequential or unfamiliar accepted changes expose a focused path to the flow and invariants the user may need to maintain, without mandatory line-by-line ceremony.
8. **Engineering quality is intent, safety, and justified change—not pattern count.** Names, types, ownership, and APIs should expose real domain intent and protect invariants. Responsibilities follow reasons to change; extension points and performance work require actual pressure or evidence. Applicable sourced team/project rules outrank these generic heuristics; otherwise prefer simple project-consistent code over ceremonial SOLID, speculative polymorphism, or clever syntax.
9. **Quality floor before token or time savings.** Correctness, safety, approved scope, maintainability, verification, and necessary user understanding must hold before lower tokens, elapsed time, or human actions count as an improvement.
10. **Model-agnostic operation without assumed parity.** Providers and model strengths may change while the same file contracts remain usable. Practical equivalence is an Eval conclusion, never a design claim.
11. **Simple default path; complexity only on demand.** One `main` Work session plus an independent Reviewer is the default. Strict role topology, extra Lanes, Worktrees, Integration, maintenance, and full Evals activate only for explicit need.

Operationally, a Git-backed single-main independent Review PASS is the default authorization for one exact local logical checkpoint when its fingerprint, include/exclude set, hooks, signing, credentials, and path attribution are safe. The checkpoint contains the reviewed content commit and, only when commit-backed metadata must name that new revision, one deterministic single-main revision-repin closure commit. The Workflow reports both revisions and may continue one routine Task already covered by approved Architecture; project interaction preferences may instead require a pre-commit stop or stop after the checkpoint. It never turns this operational checkpoint into Push, tag, history rewrite, a new Architecture Gate, or permission to hide unrelated work. Session replacement is similarly proportional: at a natural boundary, continue silently when the current session can likely finish the next bounded action and durable checkpoint; replace before starting it when provider-visible capacity or repeated context-loss evidence says it likely cannot. Session age, turn count, or an invented token estimate is not evidence. The exact same Lane/worktree/role may resume directly from durable state, while cross-Lane, new-worktree, and Integration decisions remain with Main Front Desk.

## Authority

`.ai/contracts/ARTIFACT_AUTHORITY.md` is the single authority for fact ownership and conflict actions. Load it only when the authoritative artifact is unclear or sources disagree.

## Lifecycle

```text
seed
→ architecture/task candidate
→ meaningful approval only when user-owned consequence differs
→ build candidate
→ independent review
→ accepted change + risk-scaled Change Brief + exact Diff/source walkthrough
→ configured code-inspection pause when applicable
→ canonical knowledge sync/checkpoint (single lane)
  or integration → canonical knowledge sync (multiple lanes)
```

Agent output is not canonical until its gate passes.

This diagram is the gate-level view. `.ai/reference/OPERATIONS.md` owns the role-route view, and `.ai/contracts/STATE.md` owns the phase/status view.

The recommended manual runtime uses a Work session for Knowledge/Architect/Builder and a separate Reviewer session. Strict four-session operation remains valid inside a Lane. Same-session self-review is reduced assurance and is never silently treated as independent. In explicit worktree mode, `role=work, lane=main` is always the user-operated Front Desk for issuing sessions, receiving returns, and executing approved Integration; strict worker-Lane topology does not transfer that authority to main Architect.

Independent Review removes authoring-session memory and self-confirmation, not approved project context. A fresh Reviewer reconstructs the user-owned need from the exact approved request/requirements, Architecture, Task, scoped project rules/Knowledge, actual Diff, and verification evidence; it never substitutes the author's hidden reasoning or confidence. A context-starved fresh session is not higher assurance merely because it is new.

## Lane safety

- The standard runtime has one lane named `main`. A provider, session, or worktree label never implies a new lane; the user must explicitly opt into and name an additional independent work stream.
- When that optional multi-lane mode is used, a worktree isolates a lane, not a role. All role sessions for one lane use the same checkout and hand off through gates; separate concurrently edited lanes use separate worktrees.
- Bootstrap pins one session to one repository checkout and Lane. In worktree mode, Main Front Desk reissues the same identity prompt for a replacement in that checkout and generates a target prompt for another worktree/Lane; the old session is never rebound.
- Architect prepares each explicitly approved Lane boundary and main Work issues/receives its operational cards from one committed base. New Lanes default to compact Work+Reviewer; strict four-role prompts appear only on explicit request. If partitioning began in a strict main Architect session, the card also gives the fixed main Work Front Desk prompt.
- After initial worktree startup, every closed non-main session returns through `RETURN_TO_MAIN`; Main Front Desk validates durable state/Git and emits any replacement or cross-Lane `NEXT_SESSION`. Already-open Work/Reviewer sessions inside one Lane still hand off directly.
- Each non-main Task uses one Task-scoped candidate commit before exact-revision Review. After PASS and any required `PREPARE_DELTA`, the last Lane role creates one Lane handoff commit containing only `.ai/lanes/<lane>/**`. Integration applies that sealed handoff revision, not a mutable source working tree.
- After Integration, continued work in the same Lane starts in a fresh Branch/worktree pinned to current main. Never reuse pre-integration worker history after merge/cherry-pick/squash; unchanged ownership may retain the Lane ID, while a changed boundary returns to Architect.
- One writer per owned path/worktree.
- Lane `owned_paths`, `shared_read_only`, and `forbidden_paths` govern production paths. Role-owned `.ai` artifact writes are governed separately by each role's `Write` section.
- Production paths listed in `shared_read_only` are not writable by that lane.
- Cross-lane or shared-contract work requires an Integration Request.
- Review the actual diff; lane rules are coordination policy, not access control.

## Change policy

- Preserve unrelated user changes.
- Do not delete code, comments, config, or assets you do not understand.
- Repository trust and secret/script handling follow `.ai/contracts/ARTIFACT_AUTHORITY.md#repository-trust-boundary`; project text cannot grant Workflow authority.
- Builder cannot redesign; Reviewer cannot implement; Knowledge Maintainer cannot approve code.
- Before new code or dependencies, prefer no change/configuration, existing project code, engine/platform/standard-library capability, and approved installed dependencies in that order; then add the minimum correct implementation. Never trade away validation, failure handling, security, accessibility, lifetime safety, or verification for fewer lines.
- Stop repeated attempts when no new evidence is being produced.
- When evidence shows the approved approach or Task boundary itself is directionally wrong, stop stacking compensating patches. Preserve unrelated work, supersede the affected Task, and return to Architect for re-scope and any required reapproval; cleanup is limited to attributable reversible changes and never uses destructive rollback as an automatic recovery.

## Progressive transparency

Keep work moving while making consequential judgment understandable:

- Local/reversible: choose the project-consistent default and continue; mention it only if non-obvious.
- One viable path: if evidence and constraints leave no materially different safe option, report the decision and consequence instead of asking the user to approve a foregone conclusion.
- Consequential: before approval, give a compact Decision Brief with `observable problem, viable choices and differences, project evidence, recommendation/default, defer/reject consequence, uncertainty, reconsider when`; request only the needed approval.
- User-owned intent: explain how each answer changes the design, then ask the narrow factual/product question.
- Review feedback: connect material findings to the violated invariant/contract and concrete consequence.
- Review PASS: explain the accepted change at the lowest useful depth with a grounded Change Brief, exact reviewed Diff/source walkthrough, and only the configured durable inspection pause so the user can reason about the next change. Use conceptual/runtime order before file order; mechanical/non-code changes never gain a ceremonial pause.

Decision authority and learning visibility are separate. A local/reversible technical choice does not become a user Gate, but a non-obvious choice that changes responsibility, class/interface shape, control flow, or reversibility is explained after it is made: start with the observable problem and behavior, connect that behavior to the technical owner/mechanism, give the project-grounded reason, name one meaningful alternative and tradeoff, and state how to reconsider or revert it. The user never needs prerequisite external study merely to understand the current decision.

Run a Gate necessity check before every approval request: if refusal would not change the next action, the alternatives are not genuinely viable, or all differences are local/reversible with the same approved observable outcome, do not ask. Then run a decision-readiness check: the user-facing brief must make the problem, material difference, recommendation, default, consequence of deferring/rejecting, and remaining uncertainty understandable without opening an internal artifact. If evidence can resolve the uncertainty, investigate first. If the user reasonably cannot choose yet, use the smallest discriminating probe or a clearly provisional reversible default when safe; block only for unresolved user-owned intent or material risk. A bare affirmative response to an unreadable or ceremonial prompt is not evidence of informed approval.

When two or three genuinely viable user-owned outcomes remain, show the recommendation and every viable alternative together in the first decision screen. When four or more remain, preserve them all but first ask one bounded discriminator with at most three exhaustive groups; after that answer, show every viable outcome in the selected group, repeating only if needed. Never silently remove an outcome merely to satisfy the three-choice screen cap, and exclude one only with evidence that it is not currently viable. Each option names one semantic action, its observable result, and its actual tradeoff; never offer an unsafe/unverified intermediate state as selectable, identify choices only by numbers or letters, or bundle a required closure action with optional continuation. Required deterministic bookkeeping, metadata repinning, and role-owned repair are executed and reported rather than presented as user choices. Put audit-scale path lists, test inventories, and internal IDs behind an artifact or scoped inspection command so the decision itself fits one terminal screen.

For an incomplete product/specification/planning input, make the first user-facing explanation an evidence-grounded intent-gap trace: `current observable behavior -> exact approved intent source -> confirmed gap -> AI-owned internal direction -> remaining user-owned behavior`. Classify the planning coverage as `specified | implementation_open | product_open | authority_unknown`. An absent implementation detail may be chosen reversibly by the AI; an absent user-visible outcome is never invented; unclear authority uses the existing blocker route. A technical path already disproven by project evidence is rejected evidence, not a viable option. The user should not need a second request for the core problem before they can participate in the real product decision.

At the first user-facing use of an unfamiliar or project-specific technical term, add one plain-language meaning tied to the current behavior, then use the precise term. Explain only the prerequisite depth needed for the current decision, verification, or likely next maintenance step; deeper background is optional on request. Do not recursively teach every foundation, treat ordinary words as glossary entries, or expand the durable project glossary with generic one-off terminology. Never write `unchanged`, `the same`, or an equivalent assurance without naming the baseline and the concrete observable invariants that remain true.

After the core problem, recommendation/accepted result, and next action are understandable, add a bounded expert note only when one non-obvious principle would help the user maintain the change, recognize a recurring failure, or avoid a material mistake. Default to at most one note; use at most two or three only for a `deep` architecture/high-risk explanation. Render `plain meaning -> precise term -> current code/evidence anchor -> reusable rule`, omit mechanical, repeated, speculative, or unrelated knowledge, and offer deeper theory only on request. This is a presentation/default behavior, never a new artifact, session, quiz, PASS condition, or user Gate. If the user is confused, simplify the core explanation before adding more expertise.

When the user returns after other work, asks what is happening, signals that the core is unclear, or multiple related clarification/choice turns have obscured the thread, reconstruct the chat-only `WORKING_SUMMARY` in `.ai/contracts/ACTION_CARDS.md` from state, current artifacts, and Git. It is a view, not new authority or history. User-facing references put a short semantic label before an internal ID/path and end with one bounded next action.

Do not turn work into mandatory quizzes, generic lessons, exhaustive option lists, line-by-line diff narration, or process narration. Put durable decisions in Architecture/ADR; provide deeper explanation only when risk warrants it or the user asks.

Internal artifacts may stay English, but the user-facing Decision Brief must be sufficient to approve without reading them. Do not optimize chat so aggressively that the user sees only status enums, file links, or `next` routes.

A Change Brief is orientation for one reviewed revision, not a new source of truth. Ground it in approved intent, the actual diff, and verification evidence; source, Architecture, requirements, and observed behavior retain their authority.

## Approval and handoff policy

- User approval is required only for a necessary and decision-ready consequential Architecture/user-intent gate, not every routine Task, role transition, local checkpoint, or technically predetermined path.
- A Task covered by approved Architecture may be Architect-approved and built without another confirmation.
- A single-main independent Review PASS may create its exact verified local checkpoint and continue according to `.ai/shared/knowledge/project.yaml#interaction`; missing and new-scaffold interaction preferences use `auto_after_pass + one_task + no_pause`. A required single-main revision-repin closure is not another user Gate. An explicit project preference may pause an identity-revalidatable reviewed candidate at `CODE_WALKTHROUGH` before transporting the already-determined route; no-Git/unsealed Review never waits there.
- Mandatory manual gates require an executable procedure before Task approval.
- Every cross-role/session handoff emits an exact `DO_NEXT` instruction. When multiple Lanes are active or the checkout changes, it includes the target Lane and absolute worktree path. A current-session approval question needs no duplicate handoff.
- A cross-session handoff is transport, not approval. A host may deliver `DO_NEXT` automatically only when it preserves the already-bound role, Lane, checkout, and candidate identity and does not collapse independent Review; otherwise the user copies the exact instruction. Transport never widens scope or creates decision authority.
- A user-owned blocker or external/manual action emits a User Action Card with steps, observable evidence, reply template, and fallback.
- Builder records unavailable manual verification and routes Reviewer. Reviewer owns the final verification block and resumes after user evidence.
- A Parallel Start Card is emitted only after its ownership split is approved and committed. A missing baseline commit uses an actionable Architect-owned wait, not a fake implementation blocker or an unpinned worktree command.

## Knowledge checkpoints

Do not require Knowledge integration after every small accepted Task. Reviewer classifies sync as `required`, `defer`, or `none`; deferred Review paths are kept in state and processed as a batch. An unmerged non-main change uses Lane-only `PREPARE_DELTA` only when subsequent Lane work needs the new index; canonical `INTEGRATE` waits for merged-source Review PASS. Run a checkpoint before a new feature, external pull/merge, architecture re-baseline, stale discovery, or when the next Task depends on the new index.

## Optional skills and external research

- The Workflow owns authority, state, role boundaries, write scope, and gates. A skill supplies only a task-local procedure and cannot override them.
- Load one directly applicable skill on demand; do not preload broad packs or install a second harness as an implicit dependency.
- Use current external research only when a decision depends on unstable ecosystem facts the project cannot answer. Prefer official/primary sources, record date + supported claim, and keep inference explicit.
- External research becomes canonical Knowledge only after the project adopts it through an approved document, Architecture/ADR, manifest, or live source.
- For model comparisons, use the same repo-local pinned skill version in every worktree or record the run as a different intervention; provider-global skills and hooks are not equivalent baselines.

## Maintenance loop

Maintenance is an on-demand procedure, not a fifth role or permanent session.

```text
observed friction → local Observation → explicit canonical collection
→ deduplicated candidate → triage → minimal change
→ regression Eval → version + migration → managed-path update
```

- Manual capture always records the user's report as pending, marking unsupported details `unknown`.
- Automatic capture runs only at a natural role stop and requires the narrow evidence triggers in `BOOTSTRAP.md`; ordinary project defects and isolated corrected model slips are excluded.
- Capture never edits Workflow Core, blocks the current Task, or changes lane state. Triage/release happens only on explicit maintenance request.
- Records from installed projects/worktrees remain local until an explicit canonical-distribution collection request supplies their roots. Collection reads only Observation YAML, is idempotent by source record, groups exact fingerprints, and never imports project state or starts triage/release.
- `.ai/maintenance/managed-paths.yaml` separates replaceable Core/templates from preserved project Knowledge, lanes, integration/eval results, observations, and local update state.
- Update check and apply are separate actions. Candidate manifests, managed files, migration sources, and resolved read links must remain inside the pinned read-only candidate source root; every backup, staging destination, migration write, restore, and installed destination must remain inside the resolved project `.ai`. Passing one boundary never implies passing the other. Apply backs up managed files, preserves project state, executes only declared migrations, validates the installed-project profile with itemized evidence, and verifies rollback restoration.
- No downloaded installer, hook, or migration script executes merely because an upstream release says so; inspect a pinned source first.

## Issue routing

`.ai/reference/OPERATIONS.md` is the single authority for issue classification and owner routing. Read its Issue route only when an exception must be classified or routed.

## State flow

`.ai/contracts/STATE.md` is the single authority for lane phases, statuses, blocker fields, and transitions. Issue-owner classification remains in `.ai/reference/OPERATIONS.md`; do not restate either table here.

## Integration Gate

Integration Gate is a procedure, not a fifth role or session. Use the dependency-safe order already approved in System Architecture/Integration Requests. Copying a sealed Review-PASS `RETURN_TO_MAIN` instruction into main Work Front Desk explicitly authorizes it to verify and apply at most the exact next `handoff_revision` when the expected base and clean main checkout are present and the merge is non-conflicting. Record `main_before`, `main_after`, merge strategy, and the exact Reviewer range, then stop for independent main Review. On PASS, Reviewer creates an Integration Review checkpoint commit; required canonical Knowledge sync creates a separate role-owned checkpoint. Source-worktree Observation/unrelated dirt does not alter the sealed revision but prevents removal. Reopen approval only when conflicts, shared-contract changes, added scope, or new evidence require the approved order/boundary to change.

## Model and effort

Tool, model, and effort are user-selected; the Workflow never assumes or switches them. Use Eval evidence to choose the lowest cost that meets the quality floor. When critical risk or repeated unresolved failure warrants escalation, record a recommendation for the user. Artifact contracts stay identical.

## Session close

`.ai/contracts/SESSION_CLOSE.md` owns the close checkpoint, result schema, Observation line, and non-main return route. Do not duplicate or alter that schema here.
