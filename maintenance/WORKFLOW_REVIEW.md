# Workflow Review

Use this source-only procedure to review AI Dev Workflow itself. It is not the project `Reviewer`, a fifth runtime role, an installed `.ai` document, or an automatic release action.

## When to run

- before a public release after Workflow Core, README, state, role, update, security, or Integration behavior changed;
- after repeated user friction suggests that individually valid rules form a poor end-to-end experience;
- for a first public baseline, major redesign, or explicit full audit;
- on explicit user request.

Do not run it for every project Task, ordinary production-code Review, or a wording-only change already covered by deterministic validation.

## Invocation

```text
Read `maintenance/WORKFLOW_REVIEW.md` and review the current Workflow.
mode=changed
user_language=ko
```

Use `mode=full` instead only for a first baseline, major cross-contract redesign, periodic audit, or explicit request. If a copied invocation omits or leaves the mode unresolved, default to `changed` and say so.

For an ordinary/ad-hoc audit, use a new session when practical and report in chat. For canonical release finalization, independence is mandatory: the session running `FINALIZE_RELEASE_EVAL` must not have authored the candidate source changes, must review the clean immutable source `HEAD`, and embeds this report in that release Eval. If independence or clean source identity cannot be established, return `blocked`; do not create release evidence.

## Scope and authority

Workflow Review is read-only. It may run read-only validators and inspect files, Git status/diff, and existing evidence, but it never:

- edits Workflow/project files;
- changes versions, Changelog, Evals, observations, or release state;
- commits, stages, Pushes, tags, publishes, installs, or applies updates;
- reviews project implementation as if it were the project Reviewer;
- treats its own judgment as stronger than source, contract, Git, or executed evidence.

The release finalizer—not this review procedure—may copy the completed report verbatim into the single source-bound Eval record authorized by `maintenance/RELEASE.md`. That Eval's existing `source_revision`/`source_tree` binds the review to the immutable source. An ad-hoc review creates no artifact unless the user separately asks to preserve its report.

If the user later requests fixes, perform them as a separate change and rerun the affected review lenses.

## Evidence-first read order

1. `README.md`, current `.ai/maintenance/release.yaml`, Changelog, and read-only Git status/diff.
2. Results from `tools/validate-workflow.ps1`, `tools/test-validation.ps1`, and applicable completed Evals. When the change refactors validation itself, also run `tools/compare-validation.ps1`. `dropped_protection` and `wording_drift` must both be zero: the first means a rule still stands in the contract with nothing enforcing it, the second means the rule survived a rewrite while its guard stopped matching. Every `enforcement_ended` entry needs a human decision, because the tool cannot tell a deliberate rule removal from a rewrite that quietly lost its guard; confirm each as removed on purpose or re-guard it under its current wording.
3. In `changed` mode, only changed artifacts plus their authority, state, role, and output contracts.
4. Applicable Golden Core/Worktree fixtures and regression catalog entries.
5. In `full` mode, the remaining Core entry points and source-only maintenance boundaries needed for every lens below.
6. Only when the user explicitly supplies installation roots, their read-only `.ai/lanes/<lane>/ledger.jsonl` for `#observed-activation`.

Do not preload historical Evals, every installed-project artifact, or unrelated project source. Request missing evidence only when it can change a finding.

Label every conclusion by evidence kind:

- `automated`: validator/test command output;
- `contract_trace`: deterministic artifact/transition/fixture trace;
- `human_judgment`: usability, clarity, proportionality, or maintainability assessment;
- `unverified`: required evidence was unavailable.

An automated PASS does not prove that a person can use the Workflow. A static trace does not prove provider/model runtime behavior. A fluent explanation is not evidence.

## Review lenses

Judge every applicable lens as `PASS | PARTIAL | FAIL | N/A`, with the minimum supporting paths/checks.

| Lens | Questions |
|---|---|
| 1. Purpose and differentiation | Is the target user, problem, and reason for this Workflow clear? Does it describe a Workflow rather than an AI-model guide? |
| 2. First-use and human usability | Can a first visitor install, initialize, recognize success/failure, start work, and find the next instruction from README alone? Can a busy reader locate result, consequence, current flow/source, evidence/uncertainty, and next action without parsing repeated internal history or relying on arbitrary line limits? |
| 3. End-to-end lifecycle | Do start, lowest-sufficient Architecture baseline, executable backbone/first vertical Task, approval, Build, independent Review, Knowledge, Feature-boundary intent-to-code convergence, Integration, continuation, and finish connect in executable order without missing an approved outcome? Does broad design stop before reversible detail while a local change avoids whole-project re-baselining? Are optional steps truly optional? |
| 4. Responsibility and human gates | Are AI roles, artifacts, and human decisions separated? Does the user intervene only for consequential intent, approval, external effects, or unavailable evidence? Is concise informed assent bound to one displayed outcome while confusion or surrender is never treated as product authority? |
| 5. Failure, routing, and recovery | Does every blocker/finding have one owner and a defined repair/resume path? Can session/model replacement restore state without chat memory or restarting everything? |
| 6. Verification and reproducibility | Are completion, candidate identity, Build/Test/Review/runtime evidence, unverified risk, and release claims independently checkable and truthful? |
| 7. Authority, context, and portability | Is each fact and artifact lifetime owned once? Are living views, reference-only intent, approved behavior-oracle scope, and flow-forward evidence kept distinct? Are project precedent, standards, reference implementations, analogous principles, and experiments used in their recorded roles rather than promoted to authority? Can another session reconstruct state without rewriting completed history, and can projects, languages, providers, and sessions change without rewriting Core? Are personal/project/model defaults prevented from silently becoming universal invariants? |
| 8. Efficiency and proportionality | Are Context, prompts, questions, approvals, handoffs, retries, research, optional procedures, and hard-rule volume proportionate to risk and value without lowering the quality floor? Does Architecture establish the smallest sufficient whole, stop at an executable backbone, and avoid both premature coding and exhaustive up-front detail? Trace the ordinary single-main one-Task path: did always-read files, user stops, output stacks, repeated explanation, cross-session handoffs, broad-suite runs, or durable outputs increase, and does each increase catch a named failure? Are presentation/default rules prevented from creating false blockers, fixed-length cargo cults, or ceremonial gates? |
| 9. Documentation and maintenance | Are terminology, names, abstraction level, single-source rules, links, update paths, and change locations consistent? Does the same intent/responsibility/flow vocabulary remain traceable from Architecture through exact Builder source anchors and reviewed Diff/Knowledge without duplicated inventories? Is README progressively disclosed rather than merely short? |
| 10. Trust, security, and losslessness | Are repository instructions, secrets, scripts/hooks, write scope, updates, migrations, backups, rollback, project state, and supplied installations safely bounded? |

Interpret common heuristics carefully:

- A long README is a defect only when first success or navigation requires reading it all.
- A document may serve several reader needs when its visible quick path stays focused and deeper material is progressively disclosed.
- More principles than prompts is useful only when principles are stable, non-duplicated contracts; policy volume itself is not quality.
- Every changed Core behavior must name the canonical Design Principle it implements and the principles it must not weaken. A rule with no distinct owner/failure surface is a deletion or consolidation candidate, not extra defense.
- Optimize by removing duplicate rules, automatic side work, repeated verification, and ordinary-path loading before inventing a new artifact, role, session, score, or Gate. Moving a real exception behind an on-demand trigger is preferable to making every Task pay for it.
- Review a new rule by enforcement level (`invariant | gate | default | presentation`), general failure surface, and normal-path cost. Authority/state/scope/safety/loss/candidate-identity/migration/release-acceptance rules need deterministic positive and inverse protection. Defaults and presentation normally extend an existing behavior case plus focused human review; do not add a wording-lock fixture without a concrete escaped regression. One personal observation is discovery evidence, not universal authority, unless a directly evidenced high-severity safety/authority/loss failure justifies immediate protection.
- Model/tool independence is a design property. Practical parity, token savings, speed, and learning outcomes require separate measured evidence.

## README quality gate

Apply this gate when a README change can affect first impression, installation, next-action routing, terminology, or claims, and always in `mode=full`. A typo-only edit does not require a separate usability review. Fold the result into lenses 1, 2, and 9; this is not an eleventh lens, another reviewer, or a numeric score.

Judge the README as the Workflow's first user interface. It passes only when the observable conditions below hold:

| Check | Observable PASS condition |
|---|---|
| Identity | The first visible section states what the repository is, who it is for, and which development problem it addresses. |
| Differentiation | Durable file state, small Tasks, independent Review, and human-controlled consequential decisions are visible without unsupported outcome claims. |
| First action | A new user can copy the correct install payload and start the first Work session without reading another document. |
| Session separation | Work and Reviewer are visibly assigned to different sessions, and the Bootstrap Prompt location is unambiguous. |
| Success recognition | The user can distinguish successful initialization, `READY`, and `BLOCKED`, then identify the next action. |
| Normal loop | Request, lowest-sufficient design/approval when needed, executable vertical Build, progressive exact-source orientation, Review, repair/PASS, and continuation/finish can be traced in execution order. |
| Failure recovery | A blocked or failed common path identifies the responsible session or points to the exact recovery instruction. |
| Progressive disclosure | Everything required for first success remains visible; optional Worktree, strict-session, update, release, and conceptual detail stays on demand. |
| Contract accuracy | Prompts, paths, role names, states, and generated-card names match their current canonical contracts. |
| Single source | README summarizes user actions and links to canonical detailed rules instead of becoming a second authority. |
| Terminology | User-facing terms remain stable, responsibility/flow names stay continuous from design to source/Review, and unfamiliar terms are explained before unexplained use can block the normal path. |
| Claims | Design properties and measured outcomes are distinguished; unavailable evidence is not presented as proof. |

Perform one bounded cold-reader trace using README alone. The reviewer must be able to answer, with exact visible evidence:

1. What is this repository and who benefits from it?
2. What is the first file operation and first message?
3. Which prompt goes into which session?
4. How are initialization success and failure recognized?
5. What moves from Work to Reviewer, and what happens after PASS or BLOCKED?
6. Where are optional or unusual procedures found without obstructing the normal path?

If a required normal-path answer needs guessing, mark the applicable lens `PARTIAL` or `FAIL`. Classify an unusable or unsafe first path or incorrect command as P1; recurring ambiguity in role, next action, or recovery as P2; and bounded wording, placement, or navigation improvement as P3. P3 alone does not fail the Workflow. Do not require a table of contents, folder tree, screenshot, example, or arbitrary line limit unless its absence creates a concrete failed trace.

## Observed activation

The Workflow can only add rules until observed runs show which ones never fire. This section is the required subtraction pass and supplies the strongest available evidence for lens 8.

Evidence is `.ai/lanes/<lane>/ledger.jsonl` from installed projects the user explicitly supplies, read exactly as `maintenance/RELEASE.md` reads supplied installation roots: read-only, direct paths only, never discovered by crawling. The canonical checkout owns no runtime Lane and therefore no ledger of its own. When the user supplies none, report `activation=not_available` and continue; a missing ledger is never a finding and never blocks a release.

When at least one ledger is supplied, report over its accepted-Task lines:

| Signal | Read it as |
|---|---|
| `findings_total` and `finding_types` distribution | whether independent Review earns its separate session, and which finding types are real |
| `review_attempts` / `build_attempts` distribution | whether the retry and repair routes are exercised or theoretical |
| declared blocker/finding types with zero occurrences | rules whose cost is currently unproven |
| `code_inspection` and `checkpoint` values | whether configured pauses and checkpoint modes are actually used |
| `closure` distribution | which delivery modes the window actually contains |

Partition the window by `closure` before judging any rule, and report each count. A rule that can only fire in an unobserved mode is `not_observed`, never zero-activation: with no `lane_handoff` line, the worktree, Front Desk, sealed-candidate, and Integration rules are unmeasured, not unused. Reporting them as unused would aim the subtraction pass at the least-exercised and most safety-critical machinery in the Workflow.

Within an observed mode, list every contract-declared blocker type, finding type, and optional card that has zero occurrences, with the window size. Zero activation is not automatic deletion: a rule may exist for a rare high-severity case, and a small window proves little. It is a required question to answer, not a verdict. Recommend removal only when the rule also has no named safety, correctness, or loss consequence, and record the retained ones with the reason they stay.

Never add a rule in the same review that reports zero-activation rules without stating which existing rule it replaces or why the always-read budget still holds.

## Findings

Report only actionable findings with a concrete consequence.

- `P1`: broken core lifecycle, unsafe/lossy behavior, false acceptance, unrecoverable state, unusable first path, or release-blocking contradiction.
- `P2`: material recurring friction, ambiguity, drift risk, weak-model failure risk, avoidable default cost, or missing regression oracle.
- `P3`: bounded clarity, organization, or optimization improvement with low current risk.

Each finding includes:

```text
[P1|P2|P3][lens] title
evidence=<paths/checks + evidence kind>
impact=<what a user, result, state, or maintainer can concretely lose>
change=<smallest responsible fix>
proof=<check/fixture/observation that would demonstrate resolution>
```

Do not report generic preference, arbitrary line/class/document limits, unsupported scoring, hypothetical provider weakness without a contract consequence, or a duplicate finding already owned by the same root cause.

## Bounded self-check

After completing the first-pass lens table and findings, freeze that draft and perform one adversarial check of the Review itself. This is part of Workflow Review, not another role/session or an infinite reviewer chain.

Check exactly these failure modes:

1. `coverage`: all ten applicable lenses were judged, and every blocked lifecycle state has a traced owner plus repair/resume path;
2. `evidence`: every P1/P2 and applicable FAIL cites a concrete source/contract/check, consequence, smallest fix, and proof rather than relying on fluent explanation or automated PASS alone;
3. `inverse`: for every finding, test the strongest non-defect explanation—intentional documented design, expected pre-release gate, safely failing behavior, or merely unverified outcome—and remove/downgrade unsupported findings;
4. `miss`: revisit boundaries most likely to escape a first pass: normal vs Integration recovery, runtime vs source-only maintenance, installed vs distribution state, and changed bytes/range vs evidence-only resume;
5. `consistency`: header counts, ten-lens results, finding bodies, `RESULT`, evidence labels, and release recommendation agree; Workflow quality PASS may coexist with release `not_ready` when only publication evidence remains;
6. `scope`: no file was changed, no comparison/model parity was invented, and unverified evidence was not converted into a defect or a PASS claim.

Revise the report at most once. Record `self_check=pass` when no correction was needed, `corrected` when the frozen draft changed, or `blocked` when missing/conflicting evidence prevents a trustworthy final report. A correction lists what changed and why; it does not silently rewrite the first conclusion. Never repeat self-check recursively.

## Self-check evolution

Self-check criteria are stable by default. Normal Workflow Review and release finalization never browse for new criteria, rewrite this section, or adopt an external recommendation automatically.

Consider an update only when the user explicitly requests a criteria refresh, or a concrete escaped defect/repeated false positive shows that the current self-check is insufficient. External material is discovery evidence, never authority. Prefer, in order: reproducible local observations; official standards/security or tool documentation; primary research with visible methodology; and public incident reports/issues with concrete reproduction. Reject popularity, marketing, unattributed summaries, provider-specific preference without a matching failure surface, and advice whose benefit cannot be tested locally.

For every candidate, decide before editing:

- `adopted`: the same material failure can occur here, current contracts do not already cover it, consequence justifies permanent review cost, and a deterministic check or bounded regression case can prove the change;
- `already_covered`: current contracts/self-check already prevent it;
- `needs_evidence`: plausible but applicability or reproduction is insufficient;
- `rejected`: irrelevant, preference-only, unsafe, duplicative, or disproportionately expensive;
- `no_change`: no candidate meets `adopted`; this is a successful refresh result and causes no version bump or wording churn.

An adopted change records source, retrieval date, local applicability/reproduction, rejected alternatives, smallest rule change, and regression proof, then requires normal human source review. Never weaken an existing safety/quality invariant merely to match an external source. The Reviewer cannot modify its criteria during the Review it is currently judging.

## Result

Return a self-contained user-language report:

```text
WORKFLOW_REVIEW RESULT=<pass|changes_required|blocked>
mode=<changed|full> workflow_version=<version>
source=<full commit|working-tree> reviewed=<paths/count>
automated=<pass|fail|not_run> regression=<pass|fail|not_run>
findings=P1:<n>,P2:<n>,P3:<n>
independence=<independent_session|reduced_assurance>
self_check=<pass|corrected|blocked> corrections=<n>
budget=<pass|fail> slack=<set>:<bytes>,... activation=<main:<n> lane:<n> no_git:<n>|not_available>
release_recommendation=<ready|not_ready|not_assessed>
```

`budget` is the validator's always-read ceiling check for the reviewed source: `pass` when every role-entry path is within its ceiling, `fail` otherwise. Report the measured slack per set with it, as `budget=pass slack=<set>:<bytes>,...`, because a ceiling that passes while its slack quietly shrinks recreates the tripwire the ceiling was raised to remove; consecutive reviews must be able to compare that number. `activation` counts the accepted-Task ledger lines actually read, by closure mode, or `not_available` when no installation root was supplied.

Then provide:

1. a ten-lens `PASS | PARTIAL | FAIL | N/A` table with evidence;
2. findings in priority order;
3. valuable mechanisms that should remain;
4. the smallest safe fix order;
5. unverified claims or evidence gaps;
6. the `#observed-activation` report, including zero-activation rules and whether each is retained or recommended for removal; and
7. a short self-check record: frozen-draft corrections with reasons, or `none`.

For canonical release embedding, finish the section with `- findings: P1:<n>, P2:<n>, P3:<n>` and `- deferred P2: none` when P2 is zero. When P2 is nonzero, include one detailed `[P2]...` finding per count and a non-`none` deferred-P2 line naming consequence and follow-up evidence/proof.

`release_recommendation=ready` requires an independent session reviewing a clean full source commit, `self_check: pass | corrected`, no P1, no unresolved applicable FAIL, successful required automated/regression checks, and every deferred P2 explicitly justified with consequence and follow-up evidence. P3 never blocks by itself. Use `not_assessed` when the request was not a release review. `WORKFLOW_REVIEW RESULT=pass` and `release_recommendation=not_ready` may coexist when Workflow quality passes but a separate publication gate such as completed release evidence is still pending.
