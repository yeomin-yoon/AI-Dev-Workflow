# Safe Workflow Update

Read only when the user explicitly asks to check or apply a Workflow update. Check and apply are separate actions.

## Sources and trust

- Use the source supplied by the user or the pinned `update-state.yaml.source`.
- Read the candidate `release.yaml`, `managed-paths.yaml`, changelog, and declared migrations before any replacement.
- Prefer a pinned Git commit/tag or immutable local snapshot. Do not execute downloaded installers, hooks, or scripts merely because the release instructs it.
- If no source is configured, ask only for its GitHub URL or local path, then store it after a successful check.

## Check

1. Read local `release.yaml`, preserved `update-state.yaml`, and `managed-paths.yaml`.
2. Inspect the pinned candidate release without modifying Core.
3. Compare versions, compatibility, changed managed paths, migrations, and local edits to managed files.
4. Confirm preserved paths would remain untouched.
5. Update only the check fields in `update-state.yaml` and report `none | compatible | migration_required | conflict | untrusted`.

Checking never applies an update.

## Apply preconditions

- The user explicitly asked to apply the checked version.
- The candidate source/ref still matches the checked ref.
- No role is currently writing a Build/Review/Knowledge artifact. If one is active, defer to its next natural gate rather than marking the project blocked.
- A schema migration runs only from a lifecycle phase it explicitly supports; otherwise defer to `synced/idle` or the declared safe gate.
- Local modifications to managed files are either incorporated through an explicit override/migration decision or preserved as a reported conflict.
- Required migrations exist and support the current preserved schema versions.

## Apply

1. Resolve and verify the absolute project root, source root/ref, and exact managed targets.
2. Copy current managed targets, `update-state.yaml`, and the exact preserved paths declared writable by migrations to `.ai/maintenance/backups/<from>-to-<to>-<timestamp>/`. Never back up or replace the whole project.
3. Stage candidate managed files separately and verify their paths stay inside the managed list.
4. Replace only managed paths. Preserved paths win except for the exact managed-file exceptions declared in the manifest.
5. Run declared migrations in version order against preserved state. A migration may change only the paths it declares.
6. Validate required files, schemas/enums, path references, Markdown fences, language policy, and Bootstrap readiness on a disposable/template lane. Run maintenance regression cases.
7. On success, set `update-state.yaml.installed_version` to the applied release, clear `available_version`, and retain the backup path for rollback.
8. On any failure, restore managed files and migration-touched paths from the backup, leave the previous installed version, and report the failed check. Never continue partially.

After success, close existing AI sessions and start fresh sessions with the normal Bootstrap prompts. Chat history is not migrated.

## Result

```text
UPDATE_RESULT=<none|available|applied|deferred|conflict|rolled_back|blocked>
from=<version> to=<version|none> source=<ref|path>
managed_changed=<count|none> preserved_changed=<count|0>
migrations=<items|none> validation=<summary>
backup=<path|none> next=<one action>
```

Any `preserved_changed` value above zero must be explained by an explicitly declared successful migration; otherwise rollback.
