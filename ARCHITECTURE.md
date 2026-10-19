# Architecture Overview

This document describes the architectural patterns, component relationships,
and design decisions across the Virtualization-Documentation repository.

## Repository Architecture

```text
Virtualization-Documentation/
├── Documentation Layer (Markdown)
│   ├── virtualization/           # Published docs (Open Publishing pipeline)
│   ├── prospective-docs/         # Draft content under review
│   └── tlfs/                     # Formal specifications (PDF)
│
├── Sample Applications Layer
│   └── windows-container-samples/
│       └── ASP-NET-Blog-Application/  # Containerized BlogEngine.NET
│
├── Tools Layer (PowerShell Modules)
│   └── hyperv-tools/
│       ├── Convert-WindowsImage/      # VHD(X) creation from install media
│       ├── DiscreteDeviceAssignment/  # GPU/device passthrough
│       ├── DumpEncryption/            # VM crash dump encryption
│       ├── HyperVLogs/                # Event log parsing/analysis
│       ├── ic-update/                 # Integration Components updates
│       ├── Nested/                    # Nested virtualization enablement
│       └── root-memory-reserve/       # Root partition memory mgmt
│
├── Legacy Samples
│   ├── hyperv-samples/           # Hyper-V WMI/API samples (C#, PowerShell)
│   ├── demos/                    # Conference presentations
│   └── windows-server-container-tools/  # Container utilities
│
└── Infrastructure
    ├── .github/workflows/        # CI/CD pipelines
    ├── .openpublishing.*         # DocFX/Open Publishing config
    └── package.json              # Node tooling (markdownlint)
```

## Component Architectures

### 1. ASP.NET Blog Application (Container Sample)

**Purpose**: Demonstrate Windows containerization of a legacy ASP.NET 4.x application with SQL Server.

```text
┌─────────────────────────────────────────────────────────────┐
│                    docker-compose.yml                        │
├──────────────────────┬──────────────────────────────────────┤
│        db            │                web                    │
│  mcr.microsoft.com/  │         Custom Dockerfile             │
│  mssql/server:2019   │         (Windows/Linux variants)      │
│                      │                                       │
│  - SA_PASSWORD       │  - DB_HOST=db                         │
│  - ACCEPT_EULA=Y     │  - DB_NAME=blogengine_db              │
│  - Healthcheck       │  - DB_USER=sa                         │
│  - Init scripts      │  - DB_PASSWORD (shared secret)        │
│    /docker-entry-    │  - Depends on db:healthy              │
│    point-initdb.d/   │                                       │
└──────────────────────┴──────────────────────────────────────┘
```

**Data Flow**:

1. Container starts → SQL Server initializes → Runs `/docker-entrypoint-initdb.d/*.sql`
2. `Setup-blogdatabase.sql` creates database, sets compatibility level
3. `Setup-blogtables.sql` creates 28 BlogEngine.NET tables with PKs/FKs
4. Web container starts after `db:healthy` → Connects via connection string
5. Application serves HTTP on port 80

**Security Boundaries**:

- Shared secret (`DB_PASSWORD`) passed via environment — **not production pattern**
- No TLS between containers — add reverse proxy (NGINX/Traefik) for production
- `sa` account used — create dedicated low-privilege user for production

**Testing Architecture**:

```text
schema.Tests.ps1 (Pester)
    │
    ├─► Starts disposable SQL Server container
    ├─► Applies schema scripts via docker cp + sqlcmd
    ├─► Asserts: 28 tables exist, all in dbo schema
    ├─► Asserts: Primary keys on all tables
    ├─► Asserts: Foreign key constraints exist
    └─► Tears down container (pass or fail)
```

### 2. Convert-WindowsImage (Flagship Hyper-V Tool)

**Purpose**: Create bootable VHD/VHDX from Windows installation media (ISO/WIM).

**Module Structure**:

```text
Convert-WindowsImage.psm1 (184 KB, ~4700 lines)
│
├─ Convert-WindowsImage (main function)
│   ├─ Parameter validation (ValidateScript, ValidateNotNullOrEmpty)
│   ├─ Source media handling (ISO mount, WIM extraction)
│   ├─ VHD(X) creation (New-VHD, Mount-VHD)
│   ├─ Disk layout (BIOS/MBR, UEFI/GPT, WindowsToGo)
│   ├─ Image application (DISM /Apply-Image)
│   ├─ Driver injection (DISM /Add-Driver)
│   ├─ Unattend.xml injection
│   ├─ BCD boot configuration (BCDBOOT)
│   ├─ Feature/Package installation (DISM /Enable-Feature, /Add-Package)
│   ├─ Debugger configuration (Serial, 1394, USB, Network)
│   └─ Cleanup / Dismount
│
├─ Helper functions (private)
│   ├─ Get-WimInfo, Get-IsoInfo
│   ├─ New-UnattendXml
│   ├─ Invoke-Dism, Invoke-Bcdboot
│   └─ Logging/Progress reporting
│
└─ Tests: Convert-WindowsImage.tests.ps1 (basic smoke test)
```

**Key Design Decisions**:

| Decision | Rationale |
|----------|-----------|
| Single monolithic function | Historical; refactoring blocked by compatibility requirements |
| DISM/BCDBOOT external calls | Native Windows tooling; no managed API equivalent |
| Dynamic VHD default | Space-efficient for development/test scenarios |
| UEFI/GPT default | Modern hardware requirement; Gen2 VMs |
| No parallel processing | Sequential DISM operations; dependency chain |

**Extension Points**:

- `-MergeFolder` — Inject custom files to VHD root
- `-Driver` — Inject `.inf` drivers (e.g., VirtIO, storage)
- `-Feature` / `-Package` — Enable Windows features, install updates
- `-UnattendPath` — Full unattended installation XML
- `-EnableDebugger` — Kernel debugging (Serial/USB/Network)

### 3. Hyper-V Tools (Shared Patterns)

All tools in `hyperv-tools/` follow common patterns:

**Module Structure**:

```text
ToolName/
├── ToolName.psm1          # Module manifest + functions
├── ToolName.psd1          # Module manifest (version, dependencies)
├── ToolName.tests.ps1     # Pester tests (where present)
└── README.md              # Usage documentation
```

**Common Patterns**:

- **CmdletBinding** with `DefaultParameterSetName`, `HelpURI`
- **ValidateScript** for path existence, file types, prerequisites
- **Write-Host** for progress (not Write-Output — avoids pipeline pollution)
- **try/finally** for resource cleanup (VHD mounts, temp dirs, COM objects)
- **ErrorActionPreference = "Stop"** — Fail fast on errors
- **Requires -RunAsAdministrator** — Most tools need elevation

**Dependencies**:

- Windows PowerShell 5.1+ / PowerShell 7+
- Hyper-V module (`Get-Module Hyper-V`)
- DISM, BCDBOOT, diskpart (system tools)
- WMI/CIM for hardware queries

### 4. Documentation Pipeline (Open Publishing)

**Build Flow**:

```text
Markdown source (virtualization/)
    │
    ▼
.openpublishing.build.ps1 (DocFX wrapper)
    │
    ├─► Metadata validation (YAML front matter)
    ├─► Cross-reference resolution (xref maps)
    ├─► Markdownlint (CI gate)
    ├─► DocFX build → _site/
    └─► Publish to docs.microsoft.com (via OPS)
```

**Configuration Files**:

- `.openpublishing.publish.config.json` — Repo metadata, build config, locales
- `.openpublishing.redirection.json` — URL redirects for moved content
- `.openpublishing.build.ps1` — Custom build steps (pre/post DocFX)
- `.localization-config` — Translation settings

**Content Architecture**:

- **Conceptual** — How-to guides, overviews (`*.md` with `ms.topic: conceptual`)
- **Reference** — Cmdlet/API reference (auto-generated from PowerShell help)
- **Tutorial** — Step-by-step walkthroughs
- **Landing pages** — `_index.md` with child metadata

## Cross-Cutting Concerns

### Configuration Management

| Layer | Mechanism | Example |
|-------|-----------|---------|
| Container samples | `.env` + `docker-compose.yml` | `DB_PASSWORD`, `DB_NAME` |
| PowerShell tools | Function parameters + env vars | `-VHDPath`, `$env:Temp` |
| Documentation | YAML front matter + config JSON | `ms.topic`, `author`, `locale` |
| CI/CD | GitHub Actions secrets + vars | `SA_PASSWORD_TEST` |

### Error Handling Strategy

| Component | Approach |
|-----------|----------|
| PowerShell modules | `$ErrorActionPreference = "Stop"`; `try/catch/finally`; `throw` with context |
| SQL scripts | `GO` batches; `TRY/CATCH` in newer scripts; exit codes via `sqlcmd -b` |
| Container healthchecks | `sqlcmd SELECT 1` loop; Docker `healthcheck` with retries |
| CI workflows | `set -e` / `$ErrorActionPreference`; fail fast on lint/test failures |

### Logging & Observability

| Component | Current State | Gap |
|-----------|---------------|-----|
| Convert-WindowsImage | `Write-Host` progress, `Write-Verbose` debug | No structured logging, no log file output |
| Schema tests | `Write-Host` colored output | No machine-readable output (JUnit/XML) |
| Documentation build | DocFX console output | No centralized build metrics |
| CI workflows | GitHub Actions logs | No external log aggregation |

**Planned Improvements**:

- Add `-LogPath` parameter to Convert-WindowsImage for file logging
- Emit Pester test results as NUnit XML for CI dashboards
- Add GitHub Actions workflow summaries with test counts

## Deployment Architectures

### Documentation (Production)

- **Platform**: Microsoft Open Publishing System (OPS) → docs.microsoft.com
- **Trigger**: Merge to `main` branch
- **Artifacts**: Static HTML, PDF, xref maps
- **Rollback**: OPS versioning + Git revert

### Container Samples (Development)

- **Platform**: Docker Desktop (Windows/Linux containers)
- **Orchestration**: Docker Compose (single-host)
- **Production Path**: Kubernetes (AKS) / Azure Container Apps — not in this repo

### Hyper-V Tools (End-User)

- **Distribution**: GitHub releases (ZIP), PowerShell Gallery (planned)
- **Installation**: Manual import (`Import-Module`) or `Install-Module`
- **Execution**: Interactive PowerShell (admin), automation scripts

## Technology Stack Summary

| Category | Technologies |
|----------|--------------|
| **Languages** | PowerShell 5.1/7, T-SQL, C# (legacy samples), Markdown |
| **Container Runtime** | Docker (Windows & Linux containers) |
| **Database** | SQL Server 2019 (Linux container), SQL Server 2014 Express (legacy) |
| **CI/CD** | GitHub Actions (ubuntu-latest, windows-latest) |
| **Linting** | markdownlint (Node), PSScriptAnalyzer (PowerShell) |
| **Testing** | Pester 5 (PowerShell), sqlcmd (SQL validation) |
| **Documentation** | DocFX, Open Publishing System, YAML front matter |
| **Virtualization** | Hyper-V API (WMI/CIM), VHD/VHDX, DISM, BCDBOOT |

## Architectural Decision Records (ADRs)

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| 001 | Use Docker Compose for container samples | Accepted | 2023 |
| 002 | PowerShell 5.1+ as minimum for tools | Accepted | 2022 |
| 003 | Markdown + DocFX for documentation | Accepted | 2021 |
| 004 | Pester for PowerShell testing | Accepted | 2022 |
| 005 | GitHub Actions for CI/CD | Accepted | 2023 |

*ADRs are tracked in GitHub Discussions; see [Architecture Decisions](../../discussions/categories/architecture-decisions)*

## Future Architecture Work

1. **Modularize Convert-WindowsImage** — Split into composable functions (disk, image, boot, config)
2. **Add structured logging** — JSON output for all tools, correlate with CI
3. **Container sample modernization** — Kubernetes manifests, Helm charts, GitOps
4. **Documentation as code** — Automated link checking, freshness alerts, translation pipeline
5. **Supply chain security** — SLSA provenance, signed releases, SBOM generation

---

Architecture version: 1.0
Last reviewed: 2026-10-19
Next review: 2027-01-19
