# Architecture

This repository is a **documentation and sample-code archive** for Microsoft
Windows virtualization and container technologies. It is not an application
or a data pipeline: there is no runtime service, no orchestration layer, and
no data-processing code to deploy.

## Repository layout

| Path | Purpose |
| --- | --- |
| `virtualization/` | Mirrored documentation for the MSDN virtualization site. Folder structure matches the site's URL structure (e.g. `virtualization/hyperv_on_windows/user_guide/checkpoints.md`). |
| `demos/` | One-off Hyper-V demo scripts from presentations and conferences. Not production code. |
| `hyperv-samples/`, `windows-container-samples/` | Walkthroughs and runnable samples for Hyper-V and Windows containers. |
| `hyperv-tools/`, `windows-server-container-tools/` | Scripts that automate Hyper-V / Windows Container tasks. |
| `prospective-docs/` | Draft documentation awaiting review. |
| `tlfs/` | TLFS (hypervisor top-level functional specification) related content. |

## The ASP-NET-Blog-Application sample

`windows-container-samples/ASP-NET-Blog-Application/` is a **self-contained
demo** that shows how to run a BlogEngine.NET web app and a SQL Server
database as Windows containers with Docker Compose. It is a sample, not a
component of any larger system:

- `db/` — SQL Server container image with two schema scripts:
  - `Setup-blogdatabase.sql` — creates the `blogengine_db` database.
  - `Setup-blogtables.sql` — creates the 28 BlogEngine.NET tables and their
    constraints. Stored as a single script because the foreign-key
    constraints at the end of the file depend on all tables existing first.
- `web/` — Windows Server Core + IIS image that downloads BlogEngine.NET and
  points it at the `db` service.
- `docker-compose.yml` — brings up the `db` and `web` services.
- `tests/run-schema-test.ps1` — schema validation test (see below).

Because the sample's Dockerfiles use Windows-only base images, the container
images can only be built on a Docker daemon configured for Windows
containers. The SQL schema scripts, however, are plain T-SQL and are
validated in CI against SQL Server on Linux.

## Testing

The only automated test in this repository is the blog sample's schema
validation test:

```bash
pwsh windows-container-samples/ASP-NET-Blog-Application/tests/run-schema-test.ps1
```

It starts a disposable SQL Server container, applies both `db/*.sql` scripts,
and asserts that all 28 expected tables exist. It is wired into CI via
`.github/workflows/asp-net-blog-sample.yml`.

## CI

`.github/workflows/asp-net-blog-sample.yml` runs the schema validation test
on every push / pull request that touches the sample. The Windows container
images themselves cannot be built on GitHub-hosted runners, so CI validates
the testable artifact (the T-SQL schema) instead.