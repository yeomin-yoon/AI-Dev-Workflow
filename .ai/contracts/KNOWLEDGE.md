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

Search hints identify candidates, not applicability. Before an entry is stored as `verified` or returned as evidence, inspect the referenced source and confirm its actual scope, revision/freshness, authority or owner, interface/schema when relevant, and runtime or behavioral role. A matching filename, symbol, keyword, embedding score, or nearby example alone is insufficient. Keep unresolved candidates `unknown | stale | conflict` and expand only the targeted evidence needed by the current question or Task.

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

A requirement-bearing `document` source records approval separately from source freshness. Use the exact requirement ID or section; never infer approval from a newer file date or from implementation agreement.

```yaml
schema_version: 2
id: combat-requirements
kind: document
summary: Approved combat behavior requirements and candidate changes.
sources:
  - path: Docs/CombatPRD.md
    section: REQ-COMBAT-4
    revision: abc1234
    requirement_id: REQ-COMBAT-4
    approval:
      status: approved
      basis: user:<durable-decision-ref>
search: [REQ-COMBAT-4, combat requirements]
verification:
  status: verified
  source_revision: abc1234
```

`approval.status` is `approved | candidate | rejected | superseded | unknown`. `approval.basis` names the durable user decision or document approval marker and is `null` when unknown. `verification.status` describes source accuracy/freshness; it never substitutes for requirement approval.

Historical schema-v2 document entries without `approval` remain readable as `approval.status: unknown`; absence alone does not block installation, update, or unrelated Build work. Before an Architecture or Task relies on that document as approved authority, resolve approval from durable evidence or route `context`/`contract` instead of guessing.

Do not store source copies, every private member, Git history, full logs/docs, line-only references, unsourced claims, or task-local reasoning.

A `rule` entry must identify the applicable paths/modules/languages, its exact document/config/CI source and revision, any mechanical enforcement, and `verified | inferred | stale | unknown | conflict` status. Explicit scoped rules remain distinct from dominant existing-code conventions, which are only `inferred` until adopted. Generic language/framework advice is not project Knowledge by itself.

```yaml
schema_version: 2
id: source-format
kind: rule
summary: Source files use the repository formatter configuration.
scope:
  paths: [Source/**]
  languages: [cpp]
sources:
  - path: .clang-format
    section: root configuration
    revision: abc1234
enforcement:
  kind: formatter
  command: clang-format --dry-run --Werror <task-paths>
refs:
  related: []
search: [.clang-format, Source]
verification:
  status: verified
  source_revision: abc1234
```

Keep rule content only in its `knowledge/rules/**` entry. `project.yaml.rule_refs` is the canonical list of entry paths; `PROJECT.md#rule-index` may project only `ref + scope + status + source`, never a second copy of the rule text.

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
