# Golden Core Behavior

Use these deterministic contract fixtures for a source-bound release regression when request intake, Task decomposition, Review judgment, project-rule precedence, or terminal state changes. They define the expected artifact/route oracle; they do not claim a provider/model was exercised.

## Fixture 1 — Variable-detail request

Given the same project evidence:

```text
short seed: "Add inventory sorting."

detailed seed:
Goal: Add inventory sorting.
Why: Players must find combat items quickly.
Context: existing replicated UE inventory; keyboard/controller UI.
Priority: correctness, then maintainability.
Constraint: preserve save compatibility.
Done: name/type/value order works and replication/save tests pass.
```

Expected:

- Both inputs may enter Architect without a mandatory form.
- The detailed request's goal, rationale, context, priority, constraint, and completion conditions appear in the appropriate Architecture/Task fields and are not re-asked.
- Existing engine/version, commands, conventions, and relevant behavior come from sourced project files rather than user repetition.
- Only a missing user-owned choice that materially changes scope, structure, risk, or acceptance may produce a question; routine output format or already-known context may not.

## Fixture 2 — Project-rule conflict

Given:

- `Docs/Coding.md` declares tabs for `Source/**`.
- `.clang-format` mechanically enforces spaces for the same paths.
- Existing source is mixed and no approved resolution exists.

Expected:

- Knowledge records both exact sources, common scope, enforcement, and `conflict`; it does not copy either rule into `PROJECT.md`.
- Builder does not choose whichever source was read last.
- Reviewer does not blame the implementation with a generic style finding. It routes the material conflict as `context` or `contract` to the owning source and names the concrete affected check/path.
- Once resolved, the rule entry has one canonical content source under `knowledge/rules/**`; Project Profile and `project.yaml` keep references only.

## Fixture 3 — Evidence-based code quality

Given a candidate that passes every AC and project rule, with no evidenced second implementation, variation pressure, invalid-use risk, measured hot path, or ownership/lifetime defect, and the only proposed finding is:

```text
"Add an interface and split this class because SOLID prefers it."
```

Expected:

- Reviewer does not create a blocking finding from the generic principle.
- An architecture/implementation finding is valid only after naming a concrete violated invariant/contract and consequence supported by project evidence.
- Existing simple code remains acceptable; fewer/more classes, virtual dispatch, smart-pointer form, line count, or pattern count is not an oracle by itself.

## Fixture 4 — Terminal PASS without Knowledge work

Given:

- state is `accepted/active`;
- the final Task Review is PASS with `knowledge_sync: none`;
- `knowledge_sync.pending_reviews` is empty;
- no next approved Task or active work exists.

Expected:

- state transitions directly to `synced/idle`;
- Build/Review history remains in artifacts/Git while current state stays a pointer record;
- `next.role: architect`, `next.action: await_feature_seed`;
- no empty Knowledge handoff, extra approval, or invented completion phase occurs.

If an older pending Review exists or the current Review is `defer|required`, this fixture does not apply; complete the required Knowledge checkpoint first.

## Fixture 5 — Deterministic single-main fingerprint

Given a Git-backed single-main Task changes tracked `Source/Game/New.cpp`, deletes `Source/Game/Old.cpp`, and creates untracked regular file `!Generated/Local.txt`:

- `base` is the fixed first manifest line and is excluded from sorting;
- only normalized repository-relative `path` rows are ordinal-sorted, so `!Generated/Local.txt` sorts before `Source/**` without moving the header;
- tracked files use their exact Git mode, the untracked regular file uses literal `regular`, and deleted endpoints use `deleted` for both final fields;
- Builder and Reviewer use the identical reconciled path set, UTF-8/LF bytes, `/` separators, tabs, and one final LF.

Expected: both independently produce byte-identical manifests and the same SHA-256 fingerprint. An unsupported untracked special file type makes the candidate `unsealed`; neither role guesses a mode.

## Fixture 6 — Task Quality Gate

Given four proposed slices under one approved Weapon Architecture:

- A: `Implement the weapon system`, combining equip, fire, reload, UI, animation, and replication with different oracles.
- B: `Declare Fire()` with no independently observable behavior or verification.
- C: `Process one fire request through the approved weapon component`, with existing dependencies, narrow complete writes, observable ammo/shot outcomes, and executable focused checks.
- D: the same as C, but it depends on an unapproved public event contract or has no feasible mandatory verification method/user procedure.

Expected:

- A returns `SPLIT`; Architect creates smaller independently verifiable slices and evaluates only the next one just in time.
- B returns `MERGE`; a declaration/file/function boundary without a standalone oracle is combined with the atomic behavior it supports.
- C returns `READY` and is the only proposed slice that may reach Builder.
- D returns `BLOCKED` and routes the unresolved contract or verification owner without Builder guessing.
- The Task Record fields prove the decision. A numeric score or bare pass label is not evidence, and `SPLIT`/`MERGE` do not create a user gate unless they expose a consequential user-owned choice.
