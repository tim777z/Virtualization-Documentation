<#
.SYNOPSIS
    Pester tests validating that the blog database schema scripts apply cleanly
    to a SQL Server instance and that every expected table is created.

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
    Invoke-Pester ./tests/schema.Tests.ps1

.EXAMPLE
    Invoke-Pester ./tests/schema.Tests.ps1 -ContainerImage microsoft/mssql-server-2014-express-windows
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

Describe "BlogEngine.NET Database Schema Validation" -Tag "Schema", "Database" {
    BeforeAll {
        # Fail fast with a clear message when Docker is not installed/usable.
        $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
        if (-not $dockerPath) {
            throw "Docker CLI not found. Install Docker and make sure the daemon is running before running this test."
        }

        # Ensure schema scripts exist
        if (-not (Test-Path $dbScript)) { throw "Schema script not found: $dbScript" }
        if (-not (Test-Path $tablesScript)) { throw "Schema script not found: $tablesScript" }

        # Start SQL Server container
        Write-Host "==> Starting SQL Server container '$ContainerName' from $ContainerImage"
        $null = docker rm -f $ContainerName 2>$null
        $null = docker run -d --name $ContainerName `
            -e "ACCEPT_EULA=Y" `
            -e "SA_PASSWORD=$SaPassword" `
            $ContainerImage
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start SQL Server container. Is the Docker daemon running?"
        }

        # Wait for SQL Server to accept connections
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

        # Apply schema scripts
        Write-Host "==> Applying db/Setup-blogdatabase.sql"
        docker cp $dbScript "${ContainerName}:/tmp/Setup-blogdatabase.sql" | Out-Null
        $null = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -i /tmp/Setup-blogdatabase.sql -b 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Setup-blogdatabase.sql failed to apply." }

        Write-Host "==> Applying db/Setup-blogtables.sql"
        docker cp $tablesScript "${ContainerName}:/tmp/Setup-blogtables.sql" | Out-Null
        $null = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -i /tmp/Setup-blogtables.sql -b 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Setup-blogtables.sql failed to apply." }
    }

    AfterAll {
        Write-Host "==> Removing test container '$ContainerName'"
        $null = docker rm -f $ContainerName 2>$null
    }

    It "All 28 expected BlogEngine.NET tables exist in blogengine_db" {
        $query = "SET NOCOUNT ON; USE [blogengine_db]; SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo') ORDER BY name;"
        $output = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q $query -b -h -1 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Failed to query sys.tables." }

        $actualTables = @($output | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^be_" })
        $missing = @($expectedTables | Where-Object { $_ -notin $actualTables })
        $extra   = @($actualTables | Where-Object { $_ -notin $expectedTables })

        $missing.Count | Should -Be 0 -Because "All expected tables must exist"
        if ($extra.Count -gt 0) {
            Write-Host "WARN: Unexpected tables found: $($extra -join ', ')" -ForegroundColor Yellow
        }
    }

    It "Each expected table has the correct schema (dbo)" {
        $query = "SET NOCOUNT ON; USE [blogengine_db]; SELECT TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN ('$($expectedTables -join "','")') AND TABLE_TYPE = 'BASE TABLE';"
        $output = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q $query -b -h -1 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Failed to query INFORMATION_SCHEMA.TABLES." }

        $schemas = @($output | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        foreach ($schema in $schemas) {
            $schema | Should -Be "dbo" -Because "All tables must be in dbo schema"
        }
    }

    It "Primary keys exist on all expected tables" {
        $query = @"
SET NOCOUNT ON;
USE [blogengine_db];
SELECT t.name AS TableName
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
WHERE i.is_primary_key = 1
  AND t.name IN ('$($expectedTables -join "','")')
ORDER BY t.name;
"@
        $output = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q $query -b -h -1 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Failed to query primary keys." }

        $tablesWithPk = @($output | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        $tablesWithPk.Count | Should -Be $expectedTables.Count -Because "Every table must have a primary key"
    }

    It "Foreign key constraints are created" {
        $query = @"
SET NOCOUNT ON;
USE [blogengine_db];
SELECT COUNT(*) AS FkCount
FROM sys.foreign_keys
WHERE parent_object_id IN (SELECT object_id FROM sys.tables WHERE name LIKE 'be_%');
"@
        $output = docker exec $ContainerName /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U sa -P $SaPassword -Q $query -b -h -1 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Failed to query foreign keys." }

        $fkCount = [int]($output | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^\d+$" } | Select-Object -First 1)
        $fkCount | Should -BeGreaterThan 0 -Because "Foreign key constraints must exist for referential integrity"
    }
}