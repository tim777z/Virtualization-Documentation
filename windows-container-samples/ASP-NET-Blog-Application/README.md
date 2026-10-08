# ASP.NET Blog Application (Windows Containers)

A self-contained sample that runs [BlogEngine.NET](http://dnbe.net/) and a
SQL Server database as Windows containers with Docker Compose.

```
web (Windows Server Core + IIS + BlogEngine.NET)
  |
  |  Server=db;Database=blogengine_db;User ID=sa
  v
db  (SQL Server 2014 Express for Windows)
```

This is a **demo sample**, not a production deployment. It is not a data
pipeline component and has no relationship to the rest of this repository
beyond being a walkthrough of Windows container networking.

## Prerequisites

### Windows Containers (Full Stack)
- Docker for Windows configured for **Windows containers** (the Dockerfiles
  are based on `microsoft/windowsservercore` and
  `microsoft/mssql-server-2014-express-windows`, which are Windows-only
  images).
- The sample targets the .NET Framework 4.5 / IIS 8-era toolchain used by
  BlogEngine.NET; no local .NET SDK is required because the web image
  downloads and installs the app at build time.

### Linux/macOS (Database Only - for CI and Schema Testing)
- Docker with Linux containers (default on Linux/macOS, Docker Desktop on Windows)
- The SQL schema scripts are plain T-SQL and work with SQL Server on Linux.
- Use `docker-compose.linux.yml` for database-only validation.

## Build and run

### Windows Containers (Full Stack)
```bash
docker-compose build
docker-compose up
```

The web app is then available at `http://localhost/`.

### Linux/macOS (Database Only)
```bash
docker compose -f docker-compose.linux.yml up -d
# Run schema validation tests
pwsh ./tests/schema.Tests.ps1
```

### Environment variables

Copy `.env.example` to `.env` and adjust as needed:

| Variable | Default | Description |
| --- | --- | --- |
| `DB_PASSWORD` | `Password123` | SQL Server `sa` password (must meet SQL Server complexity policy). |
| `DB_NAME` | `blogengine_db` | Database created by `db/Setup-blogdatabase.sql`. |
| `DB_HOST` | `db` | Hostname of the db service as seen from the web service. |
| `DB_USER` | `sa` | SQL Server login used by the web connection string. |

The web service's connection string is baked into `web/Web.config`
(`Server=db;Database=blogengine_db;User ID=sa; Password=Password123`); if you
change `DB_PASSWORD`/`DB_NAME` in `.env`, update `web/Web.config` to match.

## Running manually (without Compose)

```bash
docker run -it --name "db" -p 1433:1433 <db container image>
docker run -it -p 80:80 <web container image>
```

Base images (Windows):

```bash
docker pull microsoft/windowsservercore
docker pull microsoft/mssql-server-2014-express-windows
```

Base image (Linux DB only):

```bash
docker pull mcr.microsoft.com/mssql/server:2019-latest
```

## Testing

The schema scripts are validated by automated Pester tests that start a
disposable SQL Server container, apply both `db/*.sql` scripts, and assert
that all 28 BlogEngine.NET tables exist with proper primary keys and foreign
key constraints:

```bash
# Run Pester tests (requires Pester module: Install-Module -Name Pester)
Invoke-Pester ./tests/schema.Tests.ps1 -Output Detailed
```

Or using the legacy script (deprecated, kept for compatibility):
```bash
pwsh ./tests/run-schema-test.ps1
```

The Pester tests run in CI (`.github/workflows/asp-net-blog-sample.yml`) on
every push / pull request that touches this sample. Any edit to
`db/Setup-blogdatabase.sql` or `db/Setup-blogtables.sql` must land in the
same commit as the corresponding update to `tests/schema.Tests.ps1`.

## Notes

- `db/Setup-blogdatabase.sql` creates the database without explicit
  `FILENAME` clauses so it works in containers and on any SQL Server
  instance, not just the original developer's machine.
- `db/Setup-blogtables.sql` is a single script (28 tables plus their
  foreign-key constraints) because the constraints at the end of the file
  depend on all tables existing first.
- Useful Docker commands:

```bash
docker ps                 # view running containers
docker ps -a              # view all containers
docker-compose ps         # view services running under docker-compose
docker inspect <ID>       # view container network info
docker rmi <IMAGE ID>     # remove a container image
docker rm <CONTAINER ID>  # remove a container
```