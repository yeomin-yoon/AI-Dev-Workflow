# Contract: Integration Request

Path: `.ai/integration/requests/IR-<NNN>-<name>.md`

```markdown
---
id: IR-<NNN>
status: proposed
requesting_lane: <lane>
target_lanes: []
source_revision: <commit|working-tree>
owner: null
---

# <Title>

## Need and Evidence

## Proposed Boundary Contract

## Affected Lanes/Paths

## Compatibility/Migration

## Acceptance Criteria and Verification

## Risks

## Decision
- status:
- owner:
- rationale:
```

Use `proposed | approved | rejected | superseded`. This is an approval/boundary contract, not an execution tracker; merge progress belongs in `queue.yaml` and verification belongs in Integration Review Results.

The requester specifies needed behavior and boundaries, not another lane's implementation. Do not ship incompatible temporary contracts. Approval assigns owner, order, compatibility, and verification; Integration review verifies both sides.
