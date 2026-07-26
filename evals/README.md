# Source Eval Records

This directory stores canonical `source_regression` distribution audit/release records and is not part of the `.ai` installation copy. Historical records remain immutable under `evals/runs/`. Project-local optional `end_to_end` or `fixed_contract` comparisons, when explicitly requested, stay under that project's `.ai/evals/runs/` and are never imported as canonical release evidence.

The [Eval schema, regression catalog, Scorecard template, and quality floor](../.ai/evals/README.md) remain in `.ai/evals/`. Human-centered repository audit follows [Workflow Review](../maintenance/WORKFLOW_REVIEW.md); canonical release finalization runs that audit in a fresh session against the immutable source commit and embeds its ten-lens result in the completed record written here.
