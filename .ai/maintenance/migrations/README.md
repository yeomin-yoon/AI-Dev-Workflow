# Workflow Migrations

Versioned migrations are required only when a new Workflow release changes preserved-state schemas or paths.

Each migration declares supported `from/to` versions, exact readable/writable paths, preconditions, transformation, validation, and rollback.

Available:

- `manual-v1.11-to-manual-v1.12.md`: preserves project state while normalizing lane/state ownership, Task approval status, and Knowledge revision keys.
