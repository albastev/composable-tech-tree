# Magic-Tech Crossover Example

This example pack is intended to represent a **cross-domain capability scenario** where capabilities from different domains (e.g., magic and engineering) can satisfy the same requirements.

## Files

- `example-magic-tech-crossover.json`
  - Current JSON artifact in this pack.
  - At present, this file contains a broad **abstract schema and example snippets** for the Composable Tech Tree model.
- `postgres-example.sql`
  - Standalone PostgreSQL schema + seed data + demo queries for this crossover scenario.
- `example-interactions.md`
  - Human-readable walkthrough of example capability/query interactions.

## Running the PostgreSQL Example

Use the repository smoke-test harness to validate that SQL applies cleanly in a disposable PostgreSQL 16 container.

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\postgres-smoke-test.ps1
```

What this executes:

1. Starts Docker Compose PostgreSQL (`postgres:16`).
2. Applies `schema/postgres/schema.sql` in a clean test database.
3. Applies `examples/magic-tech-crossover/postgres-example.sql` in a separate clean test database.
4. Stops and removes containers/volumes.

For CI details and teardown notes, see `docs/postgres-sql-smoke-test.md`.

## What This Pack Demonstrates

From a modeling perspective, this pack highlights the core crossover idea:

- Requirements are capability-driven, not hardcoded tech-to-tech chains.
- A requirement can be met by different sources (including cross-tree sources).
- Query/discovery flows can combine capabilities from multiple active trees.

The JSON includes representative examples such as:

- Formula-based requirement evaluation (e.g., pressure × temperature thresholds)
- Simple capability matching evaluators
- Query payloads with multiple active trees (including a `magic_tree` reference)

## Suggested Usage

Use this pack as a reference when you want to:

1. Understand the expected data shape for trees, technologies, requirements, and capabilities.
2. Prototype evaluator behavior (`simple_match`, `formula`, and alternatives).
3. Build your own scenario where non-traditional capability sources unlock advanced technologies.

## Notes

- This is currently a **single-file** reference pack and can be expanded with additional scenario-specific definitions over time.
- As the repository grows, this folder can include separated files for tree definitions, tech definitions, and query/discovery fixtures.
