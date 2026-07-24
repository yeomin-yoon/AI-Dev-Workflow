# Canonical Knowledge Index

Store only useful sourced indexes under the needed categories:

```text
glossary.yaml modules/ features/ interfaces/ rules/ documents/
```

The glossary stores only sourced project-specific or repeatedly used terms. File count is not a goal. Canonical creation occurs in `BUILD`. In the single `main` lane, Builder changes require Review PASS; direct user edits and external pulls/merges require explicit `UPDATE/VALIDATE`. Every update validates current live source and routes architecture drift. In multi-lane work, unmerged facts stay in `knowledge-delta` and promotion requires merge. This README is managed Workflow guidance, not Knowledge output. Follow `.ai/contracts/KNOWLEDGE.md`.
