Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$composeFile = 'docker-compose.yml'
$serviceName = 'postgres-test'

$schemaDb = 'ctt_schema_apply_test'
$exampleDb = 'ctt_example_apply_test'

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    & docker compose -f $composeFile @Args
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose command failed: docker compose -f $composeFile $($Args -join ' ')"
    }
}

function Invoke-Psql {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Database,

        [Parameter(Mandatory = $false)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [string]$SqlFile
    )

    $psqlArgs = @(
        'exec', '-T', $serviceName,
        'psql', '-v', 'ON_ERROR_STOP=1',
        '-U', 'postgres',
        '-d', $Database
    )

    if ($Command) {
        $psqlArgs += @('-c', $Command)
    }

    if ($SqlFile) {
        $psqlArgs += @('-f', $SqlFile)
    }

    Invoke-Compose -Args $psqlArgs
}

function Wait-For-Postgres {
    Write-Host 'Waiting for postgres container readiness...'

    for ($i = 0; $i -lt 60; $i++) {
        & docker compose -f $composeFile exec -T $serviceName pg_isready -U postgres -d postgres *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host 'PostgreSQL is ready.'
            return
        }

        Start-Sleep -Seconds 1
    }

    throw 'Timed out waiting for PostgreSQL readiness.'
}

try {
    Write-Host 'Starting disposable PostgreSQL 16 test container...'
    Invoke-Compose -Args @('up', '-d', $serviceName)

    Wait-For-Postgres

    Write-Host "Preparing schema smoke-test database: $schemaDb"
    Invoke-Psql -Database 'postgres' -Command "DROP DATABASE IF EXISTS $schemaDb;"
    Invoke-Psql -Database 'postgres' -Command "CREATE DATABASE $schemaDb;"

    Write-Host 'Applying schema/postgres/schema.sql'
    Invoke-Psql -Database $schemaDb -SqlFile '/workspace/schema/postgres/schema.sql'

    Write-Host "Preparing example smoke-test database: $exampleDb"
    Invoke-Psql -Database 'postgres' -Command "DROP DATABASE IF EXISTS $exampleDb;"
    Invoke-Psql -Database 'postgres' -Command "CREATE DATABASE $exampleDb;"

    Write-Host 'Applying examples/magic-tech-crossover/postgres-example.sql'
    Invoke-Psql -Database $exampleDb -SqlFile '/workspace/examples/magic-tech-crossover/postgres-example.sql'

    Write-Host 'SQL smoke tests completed successfully.'
}
finally {
    Write-Host 'Tearing down disposable PostgreSQL test environment...'
    & docker compose -f $composeFile down -v --remove-orphans
}

