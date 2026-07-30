# Safe Workflow Update

Read only when the user explicitly asks to check or apply a Workflow update. Check and apply are separate actions.

## Sources and trust

- Use the source supplied by the user or the pinned `update-state.yaml.source`.
- Read the candidate `release.yaml`, `managed-paths.yaml`, changelog, and declared migrations before any replacement.
- Prefer a Git source resolved to an exact commit/tree or an immutable local snapshot. A Branch, tag, URL, or local path is only a locator and never the checked identity by itself. Do not execute downloaded installers, hooks, or scripts merely because the release instructs it.
- If `update-state.yaml.source` is null and the installed `release.yaml.source` names a repository/ref, present that metadata in `user_language` only as an untrusted source candidate and require explicit user confirmation before Check. Never treat installed metadata as update authority. If its ref is null, ask which ref/version to check; if the candidate is absent or rejected, ask only for a GitHub URL or local path. Store the confirmed source in `update-state.yaml` only after a successful Check.
- The migration list is sparse. `required: true` changes an incompatible preserved schema/path and must succeed. `required: false` is a lossless cleanup that may defer when the existing schema remains explicitly compatible. No entry is required when every installed preserved schema is compatible and no cleanup is offered; an incompatible schema without a required migration is a conflict.

Resolve two independent containment roots before Check or Apply:

- `candidate_source_root` is the resolved root against which candidate `.ai/...` paths are evaluated. For a pinned read-only Git checkout or immutable local snapshot, it is that checkout/snapshot root. If the user supplies the candidate `.ai` directory itself, its resolved parent becomes `candidate_source_root` and the supplied directory must equal `<candidate_source_root>/.ai`. Every candidate manifest, managed file, and migration source must remain inside this root. Never write to it.
- `install_root` is the target project's resolved `.ai` directory. Every backup, staging file, migration write, restore, and destination must remain inside it.

The candidate source root is read-only and is not required to be inside the target install root. Crossing from the candidate root into the install root occurs only by copying checked managed files into target-local staging during an explicitly requested Apply.

## Checked candidate identity

Check and Apply are one review transaction split by a user decision. The checked bytes, not a mutable ref name, bind that transaction.

- For Git, record the fully resolved commit and `commit^{tree}`. For every source type, also build a canonical input manifest covering the candidate `release.yaml`, `managed-paths.yaml`, changelog, declared migration metadata/source, and every concrete managed input expanded by the candidate manifest.
- Encode one record per input as `relative-path<TAB>type<TAB>size<TAB>sha256<TAB>link-identity`, sorted by ordinal normalized `.ai`-relative path and serialized as UTF-8/LF. `link-identity` is `-` for a regular file or the normalized in-root resolved target plus its type/hash for a permitted link. Hash the complete manifest with SHA-256.
- Store the checked locator/ref, resolved Git revision/tree when applicable, canonical manifest SHA-256, exact newly managed path set, and exact approved-new-managed path set in `update-state.yaml`. A historical state file missing these fields is readable but represents no applicable Check; populate it with a new Check before Apply.
- Apply must resolve and hash the source again and require byte-identical identity fields before creating staging, backup, or destination content. A moved tag/Branch, changed local directory, changed link target, missing input, or expanded-path difference invalidates the Check and stops before the first write.
- After the pre-write match, copy every checked input needed by Apply into transaction-local staging, reconstruct the same canonical manifest from the staged bytes/links, and require the checked SHA-256 again before replacing any installed path. From that point onward use only the verified staged inputs; never re-read a mutable candidate root during replacement or migration.

## Immutable path boundary

The update write target is exactly the resolved `<project>/.ai` directory. No candidate manifest, migration, symlink/junction, wildcard, relative traversal, or source layout may expand it.

- Normalize the project root, install root, candidate source root, every declared pattern, every expanded candidate input, backup, staging, migration-write, restore, and destination path before any write.
- Require every candidate input to remain inside the pinned candidate source root, and every path that may be written to remain inside the install root. Passing one boundary never implies passing the other.
- Reject an absolute/drive/UNC target, `..` traversal, unresolved link/reparse target, or any normalized destination that is not the install root itself or a descendant of `<project>/.ai/`.
- Reject candidate `managed` or `preserved` entries that are not `.ai`-relative. Resolve each candidate entry under the pinned candidate source root for read and the same relative entry under the install root for staging/destination; recheck both concrete paths independently.
- Existing preserved paths always remain preserved. If the candidate classifies an installed preserved/unknown path as managed, stop as `conflict`; never accept reclassification from candidate metadata alone.
- A newly introduced managed path that did not match the installed manifest requires an explicit user approval after showing its exact path and purpose. Approval never permits a path outside `.ai`.
- Resolve symlinks/junctions/reparse points against the containment root for the operation. For candidate reads and staging copies, resolve every link target and stop if it escapes the pinned candidate source root or cannot be resolved. For install backup, replacement, staging destination, migration write, restore, or final destination, stop if the target escapes the install root or cannot be resolved. Never copy or follow an escaping link merely because its lexical path is inside `.ai`.

## Check

1. If preserved `update-state.yaml` is missing, create it from managed `update-state.template.yaml`; then read local `release.yaml`, `update-state.yaml`, and `managed-paths.yaml`. Resolve any active transaction through the recovery procedure below before inspecting a new candidate.
2. Inspect the candidate release, resolve its source identity, and build the canonical input manifest without modifying Core.
3. Validate both manifests against the immutable path boundary, then compare versions, compatibility, changed managed paths, migrations, and local edits to managed files.
4. Confirm preserved paths would remain untouched; report every newly managed or reclassified path separately.
5. Store the checked revision/tree/manifest and exact newly managed set in `update-state.yaml`. Clear any approval left from another checked identity. If newly managed paths exist, show each exact path and purpose and require explicit approval before Apply.
6. Update the remaining check fields and report `none | compatible | migration_required | conflict | untrusted`.

Checking never applies an update.

## Interrupted transaction recovery

`update-state.yaml.active_transaction_manifest` is the durable marker. `null` means no transaction needs recovery; otherwise it is the repository-relative path to the active backup directory's exact `<backup>/transaction-manifest.yaml`. Historical state without this field is readable as `null`.

Before every Check or Apply, inspect this marker first. Resolve it strictly inside the maintenance backup root under `install_root`, require the basename `transaction-manifest.yaml`, and verify that its checked source identity matches the transaction header. Do not start another Check/Apply while it is non-null.

- If the manifest outcome is `committed`, verify the recorded final installed identities and finish only the pending marker clear; never replay replacements.
- Otherwise use the immutable pre-state and completed mutation records to perform the same verified rollback as Apply step 8. After byte-identical present/absent/type/hash/link restoration, mark the manifest `rolled_back`, then clear the marker.
- If the pointer escapes the install root, the manifest is missing/corrupt, the pre-state cannot be proven, or a current path no longer matches the transaction's recorded output/pre-state, stop `blocked` and preserve backup/staging evidence for user-directed recovery.

Creating an orphan backup directory before the marker write is not an active transaction because no installed target has changed. The marker must be durably written and journaled before the first installed target mutation.

## Apply preconditions

- The user explicitly asked to apply the checked version.
- The candidate resolves to the exact checked Git revision/tree when applicable, and its recomputed canonical input manifest SHA-256 equals the checked value. Matching only the locator/ref is insufficient.
- No role is currently writing a Build/Review/Knowledge artifact. If one is active, defer to its next natural gate rather than marking the project blocked.
- A schema migration runs only from a lifecycle phase it explicitly supports; otherwise defer to `synced/idle` or the declared safe gate.
- Local modifications to managed files are either incorporated through an explicit override/migration decision or preserved as a reported conflict.
- Required migrations exist and support the current preserved schema versions. An optional migration may defer only when the untouched installed schema remains listed compatible.
- The exact checked newly managed path set equals the explicitly approved path set recorded for this same candidate identity, and no installed preserved/unknown path was reclassified. A general Apply request never approves a path that Check did not display.
- Every candidate input path passes candidate-source read containment, and every normalized backup, staging, migration-write, restore, and destination path passes install-root write containment immediately before writing.

## Apply

1. Resolve and verify the absolute project root, `.ai` install root, pinned candidate source root/ref, exact candidate inputs, managed targets, and link/reparse destinations. Recompute the checked revision/tree/input-manifest identity and stop before any write on a mismatch. Do not require the candidate root to be under the project.
2. Before changing installed content, create `.ai/maintenance/backups/<from>-to-<to>-<timestamp>/transaction-manifest.yaml` with the checked source identity and an immutable pre-state section for every concrete target a replacement or migration may create, replace, or remove, including any missing parent path that the transaction would create. Record each path as `present | absent`; for `present`, record type/size/hash/link identity and copy its content into that backup directory. Include and back up `update-state.yaml`. Journal the marker mutation, durably set `update-state.yaml.active_transaction_manifest` to this exact manifest path, mark that mutation complete, and only then begin another installed target mutation. Before each mutation, append normalized path, action, and expected pre-state; immediately after success, append resulting type/size/hash/link identity and mark the record complete before starting the next mutation. Never back up or replace the whole project.
3. Copy every checked input needed by Apply from the read-only candidate source root into transaction-local staging under the install root. Verify every candidate read stays inside its source root and every staged source/destination stays inside the install root, reconstruct the canonical input manifest from staging, and require its SHA-256 to equal the checked value. After that verification, use only staged migration/input bytes, and allow only checked managed files to reach final destinations without overlapping preserved state.
4. Replace only managed paths. Preserved paths win except for the exact managed-file exceptions declared in the manifest.
5. Run applicable declared migrations in version order against preserved state. A migration may change only the paths it declares. A deferred optional migration reports its exact unsatisfied cleanup condition and leaves those preserved files unchanged; it does not make an otherwise compatible managed-file update partial.
6. Run the installed-project validation profile and write the exact evidence matrix defined below to `<backup>/installed-validation.md`: required managed inventory, compatible preserved schemas/enums, path containment/classification, reference integrity, Markdown fence/language policy, runtime-state preservation, and Bootstrap readiness on a disposable/template lane. Do not apply source-distribution-only rules such as requiring empty runtime lanes/Knowledge/Eval directories. The canonical distribution checkout separately runs its source validation profile.
7. Only after all seven required evidence rows are present and `pass` may Apply set `update-state.yaml.installed_version` to the applied release, clear `available_version` and the one-use approved-new-managed set, and retain the backup path for rollback. Reverify final recorded identities, mark the transaction manifest outcome `committed`, and then clear `active_transaction_manifest`. A crash before that final clear is recovered as an already-committed transaction, not replayed.
8. On any required migration or validation failure, restore every `present` pre-state path from backup. Remove a path recorded `absent` only when the transaction manifest's completed mutation record proves this Apply created it and its current identity still matches the recorded transaction output; remove newly created empty parents in deepest-first order under the same rule. If another writer changed a created path, do not delete it by assumption: stop as `blocked` and preserve evidence. Compare the complete restored present/absent/type/size/hash/link set with the transaction manifest's immutable pre-state section, leave the previous installed version, and report both the failed check and restore verification. After successful verification mark the manifest `rolled_back`, then clear `active_transaction_manifest`. A declared optional migration deferral is not a failure only when it wrote nothing and the retained schema is compatible. If restore verification fails, keep the active marker, stop as `blocked`, and preserve the backup/staging evidence; never continue from a partially written or unverified restore.

## Installed validation evidence

Apply writes exactly one row for each stable check below. `Observed result` states the concrete value/count/identity seen; `Evidence path/output` points to the inspected installed path or a durable transaction-local output. A generic assurance such as `looks good` or `validated` is not evidence.

| Check | Result | Observed result | Evidence path/output |
|---|---|---|---|
| `managed_inventory` | `<pass|fail>` | `<required/found/missing counts and identity>` | `<path or captured output>` |
| `preserved_schema_enums` | `<pass|fail>` | `<schemas/enums checked and compatibility>` | `<path or captured output>` |
| `path_containment_classification` | `<pass|fail>` | `<read/write roots and classification result>` | `<path or captured output>` |
| `reference_integrity` | `<pass|fail>` | `<references checked/broken count>` | `<path or captured output>` |
| `markdown_language_policy` | `<pass|fail>` | `<fence/language checks and counts>` | `<path or captured output>` |
| `runtime_state_preservation` | `<pass|fail>` | `<pre/post preserved-state identity>` | `<path or captured output>` |
| `bootstrap_readiness` | `<pass|fail>` | `<disposable/template lane result>` | `<path or captured output>` |

Every row is mandatory for every Apply. When a category has zero concrete items, record `pass` with the observed zero count, the applicable empty-set rule, and evidence; never skip it as `not_applicable`. A missing or duplicate row, `not_applicable`, `not_run`, an empty observation/evidence cell, or an assurance-only PASS is a validation failure and triggers step 8. Check-only results may report validation as `not_run`; Apply may not.

After success, close existing AI sessions and start fresh sessions with the normal Bootstrap prompts. Chat history is not migrated.

## Result

```text
UPDATE_RESULT=<none|available|applied|deferred|conflict|rolled_back|blocked>
from=<version> to=<version|none> source=<ref|path>
managed_changed=<count|none> preserved_changed=<count|0>
migrations=<applied|deferred|none; items> validation=<pass|fail|not_run; evidence-path|none>
backup=<path|none> restore_verification=<not_needed|pass|fail> next=<one action>
```

Any `preserved_changed` value above zero must be explained by an explicitly declared successful migration; otherwise rollback.
