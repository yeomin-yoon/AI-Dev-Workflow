# Workflow Observations

Pending evidence-backed improvement candidates live here and follow `.ai/maintenance/MAINTAIN.md`.

One compact YAML file represents one deduplicated fingerprint. These files are preserved across Workflow updates. They are not project blockers, lane history, or authority for a Core change.

Installed projects and worktrees record locally and do not share this directory automatically. On an explicit collection request, the canonical Workflow source reads only the supplied observation directories, merges matching fingerprints with source-record provenance, and leaves every source copy untouched. Collection is idempotent and is separate from triage or release.
