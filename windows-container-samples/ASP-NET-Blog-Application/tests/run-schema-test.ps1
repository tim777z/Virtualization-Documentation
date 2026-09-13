<#
.SYNOPSIS
    Validates that the blog database schema scripts apply cleanly to a SQL
    Server instance and that every expected table is created.

.DESCRIPTION
    Starts a disposable SQL Server container, applies
    db/Setup-blogdatabase.sql and db/Setup-blogtables.sql, then asserts that
    all 28 BlogEngine.NET tables exist in the 'blogengine_db' database.

    The container is removed when the test finishes (pass or fail), so the
    script is safe to run repeatedly and in CI.

    This test is intentionally committed alongside the schema scripts: any
    future edit to db/Setup-blogdatabase.sql or db/Setup-blogtables.sql must
    land in the same commit as the corresponding update to this test.

.PARAMETER ContainerImage
    SQL Server container image to test against. Defaults to the SQL Server
    2019 Linux image, which bundles /opt/mssql-tools/bin/sqlcmd. To test
    against the sample's original Windows image, pass
    -ContainerImage microsoft/mssql-server-2014-express-windows (requires a
    Docker daemon configured for Windows containers).

.PARAMETER SaPassword
    Password for the SQL Server 'sa' account. Must meet SQL Server password
    complexity policy (8+ chars, upper/lower case, digits, symbols).

.EXAMPLE
    pwsh ./tests/run-schema-test.ps1

.EXAMPLE
    pwsh ./tests/run-schema-test.ps1 -ContainerImage microsoft/mssql-server-2014-express-windows
#>
[CmdletBinding()]
param(
    [string]$ContainerImage = "mcr.microsoft.com/mssql/server:2019-latest",
    [string]$SaPassword = "P@ssw0rdTest!2024",
    [string]$ContainerName = "blogengine-schema-test"
)

$ErrorActionPreference = "Stop"

$expectedTables = @(
    "be_BlogRollItems", "be_Blogs", "be_Categories", "be_CustomFields",
    "be_DataStoreSettings", "be_FileStoreDirectory", "be_FileStoreFileThumbs",
    "be_FileStoreFiles", "be_PackageFiles", "be_Packages", "be_Pages",
    "be_PingService", "be_PostCategory", "be_PostComment", "be_PostNotify",
    "be_Posts", "be_PostTag", "be_Profiles", "be_QuickNotes",
    "be_QuickSettings", "be_Referrers", "be_RightRoles", "be_Rights",
    "be_Roles", "be_Settings", "be_StopWords", "be_UserRoles", "be_Users"
)

$dbDir = Join-Path $PSScriptRoot ".." "db"
$dbScript = Join-Path $dbDir "Setup-blogdatabase.sql"
$tablesScript = Join-Path $dbDir "Setup-blogtables.sql"

if (-not (Test-Path $dbScript)) { throw "Schema script not found: $dbScript" }
if (-not (Test-Path $tablesScript)) { throw "Schema script not found: $tablesScript" }

# Fail fast with a clear message when Docker is not installed/usable.
$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerPath) {
    throw "Docker CLI not found. Install Docker and make sure the daemon is running before running this test."
}

# Runs sqlcmd inside the test container. Returns the command output and
# records the sqlcmd exit code in $script:LastSqlCmdExitCode.
function Invoke-SqlCmdInContainer {
    param([string[]]$SqlCmdArgs)
    $output = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U sa -P $SaPassword @SqlCmdArgs 2>&1
    $script:LastSqlCmdExitCode = $LASTEXITCODE
    if ($script:LastSqlCmdExitCode -ne 0) {
        Write-Host "sqlcmd failed (exit $script:LastSqlCmdExitCode):" -ForegroundColor Red
        $output | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
    return ,$output
}

function Remove-TestContainer {
    $null = docker rm -f $ContainerName 2>$null
}

Write-Host "==> Starting SQL Server container '$ContainerName' from $ContainerImage"
Remove-TestContainer
$null = docker run -d --name $ContainerName `
    -e "ACCEPT_EULA=Y" `
    -e "SA_PASSWORD=$SaPassword" `
    $ContainerImage
if ($LASTEXITCODE -ne 0) {
    throw "Failed to start SQL Server container. Is the Docker daemon running?"
}

try {
    # --- Wait for SQL Server to accept connections -------------------------
    Write-Host "==> Waiting for SQL Server to accept connections..."
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        $null = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q "SELECT 1" -b 2>$null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 5
    }
    if (-not $ready) {
        throw "SQL Server did not become ready within 150 seconds."
    }
    Write-Host "    SQL Server is ready."

    # --- Apply schema scripts ----------------------------------------------
    Write-Host "==> Applying db/Setup-blogdatabase.sql"
    docker cp $dbScript "${ContainerName}:/tmp/Setup-blogdatabase.sql" | Out-Null
    $null = Invoke-SqlCmdInContainer @("-i", "/tmp/Setup-blogdatabase.sql", "-b")
    if ($script:LastSqlCmdExitCode -ne 0) { throw "Setup-blogdatabase.sql failed to apply." }

    Write-Host "==> Applying db/Setup-blogtables.sql"
    docker cp $tablesScript "${ContainerName}:/tmp/Setup-blogtables.sql" | Out-Null
    $null = Invoke-SqlCmdInContainer @("-i", "/tmp/Setup-blogtables.sql", "-b")
    if ($script:LastSqlCmdExitCode -ne 0) { throw "Setup-blogtables.sql failed to apply." }

    # --- Assert expected tables exist ---------------------------------------
    Write-Host "==> Verifying tables in 'blogengine_db'"
    $query = "SET NOCOUNT ON; USE [blogengine_db]; SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo') ORDER BY name;"
    $output = Invoke-SqlCmdInContainer @("-Q", $query, "-b", "-h", "-1")
    if ($script:LastSqlCmdExitCode -ne 0) { throw "Failed to query sys.tables." }

    $actualTables = @($output | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^be_" })
    $missing = @($expectedTables | Where-Object { $_ -notin $actualTables })
    $extra   = @($actualTables | Where-Object { $_ -notin $expectedTables })

    if ($missing.Count -gt 0) {
        Write-Host "FAIL: Missing tables: $($missing -join ', ')" -ForegroundColor Red
        throw "Schema validation failed: $($missing.Count) expected table(s) missing."
    }
    if ($extra.Count -gt 0) {
        Write-Host "WARN: Unexpected tables found: $($extra -join ', ')" -ForegroundColor Yellow
    }

    Write-Host "PASS: All $($expectedTables.Count) expected tables exist in 'blogengine_db'." -ForegroundColor Green
}
finally {
    Write-Host "==> Removing test container '$ContainerName'"
    Remove-TestContainer
}