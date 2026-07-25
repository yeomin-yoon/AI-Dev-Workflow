# Workflow Migrations

Versioned migrations are required when a new Workflow release makes a preserved-state schema/path incompatible. A release may also declare `required: false` for a lossless cleanup when both old and new schemas remain compatible; optional cleanup must write nothing when its preconditions are not met.

Each migration declares supported `from/to` versions, exact readable/writable paths, preconditions, transformation, validation, and rollback.

No migration is required for the first public release, `manual-v1.0`.
