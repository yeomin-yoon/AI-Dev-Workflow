# Contract: Knowledge Index

Purpose: locate authoritative source without repeatedly scanning the repository.

```text
.ai/shared/knowledge/
├── manifest.yaml
├── project.yaml
├── glossary.yaml
├── modules/
├── features/
├── interfaces/
├── rules/
└── documents/
```

Create entries only for stable, search-worthy responsibilities, public surfaces, relationships, commands, rules, and document locations.

Use root index status `uninitialized | partial | verified | stale | conflict`; entry verification remains `verified | inferred | stale | unknown | conflict`.

```yaml
schema_version: 2
id: character-health-interface
kind: interface
summary: Exposes character health and change events.
sources:
  - path: Source/Game/Public/Character/IHealthSource.h
    symbol: IHealthSource
    revision: abc1234
refs:
  architecture: .ai/shared/SYSTEM_ARCHITECTURE.md#character-ui
  related: [ui-health-widget]
search: [IHealthSource, OnHealthChanged]
verification:
  status: verified
  source_revision: abc1234
```

Do not store source copies, every private member, Git history, full logs/docs, line-only references, unsourced claims, or task-local reasoning.

`glossary.yaml` contains only durable project language:

```yaml
schema_version: 2
terms:
  - term: materialization
    meaning: Assigning a logical asset a concrete repository location.
    aliases: [materialize]
    sources:
      - path: Docs/Domain.md
        section: Materialization
        revision: abc1234
    verification:
      status: verified
      source_revision: abc1234
```

Do not use the glossary as a generic dictionary or create terms only to compress one conversation.

For the single `main` lane, Review-PASS source may update canonical knowledge after comparison with the exact reviewed live source; record `working-tree` when uncommitted. Explicit `UPDATE/VALIDATE` may also synchronize direct user edits or external pulls/merges from current live source. Structural drift keeps affected intended-structure refs `stale/conflict` until Architect resolves them. An unmerged non-`main` candidate uses `PREPARE_DELTA` under `.ai/lanes/<lane>/knowledge-delta/` only when later Lane work needs that index; it remains non-canonical and requires merge plus integrated-source validation before promotion. Use `conflict/unknown` rather than guessing.

`QUERY` is read-only by default: answer factual project questions with concise `path + symbol/section + status` sources. Target live evidence only when the index is missing or freshness matters. Report stale/conflicting entries and route design choices to Architect instead of silently rewriting Knowledge or making recommendations.
