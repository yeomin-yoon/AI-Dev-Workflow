# Lanes

A lane is a project ownership area that can be planned, built, and reviewed independently.

`main` is the normal and sufficient value, which is why the standard copy-paste prompts contain only `lane=main`. A lane is not a chat, role, model, provider, or worktree label; creating or opening a worktree does not create a lane. Add another lane only when the user explicitly chooses to develop independently buildable, non-overlapping areas in parallel and supplies that lane name to both Work and Reviewer Bootstrap prompts.

The user does not have to construct those non-main prompts. After Architect approves and the user commits the ownership partition, `.ai/contracts/PARALLEL_START.md` prints the exact main Work Front Desk prompt when needed, worktree command, topology-appropriate role prompts, and first request for each Lane. New Lanes default to compact Work+Reviewer; strict four-role topology is explicit opt-in and never changes the main Work Front Desk.

```text
virtual worker = role × lane × task
```

Rules:

- Name lanes by domain, not model.
- Keep `owned_paths` non-overlapping.
- Put shared production interfaces/build config in `shared_read_only`; `.ai` artifact permissions come from role contracts, not these production-path lists.
- Use project-relative paths/globs. `forbidden_paths` wins; a path cannot be both owned and shared-read-only.
- Lane status is `uninitialized | active | retired`; it describes lane availability, never Task progress.
- Record authoritative dependencies in System Architecture and Integration Requests. `lane.yaml.dependencies` is only their local execution projection; never add reverse `downstream_lanes` state.
- Avoid lanes whose handoff cost exceeds implementation risk.
- Combine areas that cannot be independently built, tested, or merged.

Create a lane from `_template` and replace evidence-based placeholders in `lane.yaml`, `state.yaml`, and `architecture.md`. Tool and model selection stay outside durable lane state.

New Lane files use schema `3`. Preserved schema-`2` Lane files remain readable: ignore legacy `downstream_lanes`, lane-level `verification`, `last_validated`, state `active_feature`, state `active_task`, and state `open_risks`. Do not update those keys. The declared update migration removes them only when doing so cannot discard unresolved data.

For existing projects, Knowledge Maintainer seeds `owned_paths` and `shared_read_only` from live production roots. For greenfield or new roots, Architect records the ownership decision in approved Architecture and then updates the current lane before Builder starts. Empty `owned_paths` grants no production write access.
