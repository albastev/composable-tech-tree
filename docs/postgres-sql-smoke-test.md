# PostgreSQL SQL Smoke Test

This repository includes a disposable PostgreSQL smoke-test workflow to validate that both SQL entry points apply cleanly:

- `schema/postgres/schema.sql`
- `examples/magic-tech-crossover/postgres-example.sql`

The test environment is containerized with PostgreSQL 16 and is intended for both local execution and CI.

## Files

- `docker-compose.yml`
  - Defines `postgres-test` using `postgres:16`.
  - Exposes port `55432` (optional for host use).
  - Mounts repository to `/workspace` for `psql -f` execution.
- `scripts/postgres-smoke-test.ps1`
  - Starts the test container.
  - Waits for readiness with `pg_isready`.
  - Creates isolated test databases.
  - Applies SQL files with `ON_ERROR_STOP=1`.
  - Tears down the environment (`down -v --remove-orphans`) in `finally`.
- `.github/workflows/postgres-sql-smoke-test.yml`
  - Runs the same PowerShell smoke test in GitHub Actions on push/PR.

## Local Usage

From repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\postgres-smoke-test.ps1
```

## CI Behavior

CI runs the same command in GitHub Actions:

```yaml
./scripts/postgres-smoke-test.ps1
```

## Expected Success Signal

Successful execution includes:

- Schema apply completed for `ctt_schema_apply_test`
- Example apply completed for `ctt_example_apply_test`
- Final message:

```text
SQL smoke tests completed successfully.
```

## Cleanup / Teardown

Cleanup is automatic in the script's `finally` block. If manual cleanup is ever needed:

```powershell
docker compose -f docker-compose.yml down -v --remove-orphans
```

This removes the disposable container, network, and volumes used for test runs.

