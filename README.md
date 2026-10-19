# Virtualization Documentation

Documentation, sample code, and tools for Microsoft Windows virtualization and container technologies.

## Overview

This repository contains official documentation and sample implementations for:

- **Hyper-V** — Virtualization platform for Windows Server and Windows Client
- **Windows Containers** — Application containerization on Windows
- **Hyper-V Tools** — PowerShell modules for VM management and VHD(X) creation

## Repository Structure

```text
.
├── demos/                          # Conference demos and presentations
├── hyperv-samples/                 # Hyper-V API and WMI samples
├── hyperv-tools/                   # PowerShell tools for Hyper-V management
│   ├── Convert-WindowsImage/       # Create bootable VHD(X) from Windows install media
│   ├── DiscreteDeviceAssignment/   # GPU/device passthrough samples
│   ├── DumpEncryption/             # VM dump encryption configuration
│   ├── HyperVLogs/                 # Hyper-V event log parsing
│   ├── ic-update/                  # Integration Components update scripts
│   ├── Nested/                     # Nested virtualization enablement
│   └── root-memory-reserve/        # Root partition memory reservation
├── prospective-docs/               # Draft documentation under review
├── tlfs/                           # Top Level Functional Specifications (PDFs)
├── virtualization/                 # Published documentation (Markdown)
│   ├── hyper-v-on-windows/         # Hyper-V on Windows 10/11 guides
│   ├── windowscontainers/          # Windows Containers guides
│   └── community/                  # Community-contributed content
├── windows-container-samples/      # Containerized application samples
│   └── ASP-NET-Blog-Application/   # BlogEngine.NET on SQL Server in containers
└── windows-server-container-tools/ # Container management utilities
```

## Quick Start

### Windows Container Sample: ASP.NET Blog Application

The `windows-container-samples/ASP-NET-Blog-Application` directory
contains a complete BlogEngine.NET application running on SQL Server
in containers.

**Prerequisites:**

- Docker Desktop with Windows containers support (or Linux containers for the Linux variant)
- PowerShell 7+ (for test scripts)

**Run with Docker Compose (Linux containers):**

```powershell
cd windows-container-samples/ASP-NET-Blog-Application
cp .env.example .env
# Edit .env with a strong password (min 8 chars, upper/lower/digit/symbol)
docker compose -f docker-compose.linux.yml up -d
```

**Run schema validation tests:**

```powershell
cd windows-container-samples/ASP-NET-Blog-Application
pwsh ./tests/schema.Tests.ps1
```

### Hyper-V Tools: Convert-WindowsImage

The flagship tool for creating bootable VHD(X) files from Windows installation media.

```powershell
# Import the module
Import-Module ./hyperv-tools/Convert-WindowsImage/Convert-WindowsImage.psm1

# Create a VHD from Windows ISO
Convert-WindowsImage -SourcePath D:\Win10.iso -Edition Professional -VHDPath C:\VHDs\Win10.vhdx
```

See [hyperv-tools/Convert-WindowsImage/README.md](hyperv-tools/Convert-WindowsImage/README.md) for full documentation.

## Documentation

Published documentation is available in the [`virtualization/`](virtualization/) directory and covers:

- [Hyper-V on Windows Quick Start](virtualization/hyper-v-on-windows/quick-start/)
- [Hyper-V User Guide](virtualization/hyper-v-on-windows/user-guide/)
- [Windows Containers Overview](virtualization/windowscontainers/)
- [Managing Containers](virtualization/windowscontainers/manage-containers/)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Code of conduct
- Pull request process
- Coding standards (PowerShell, SQL, Markdown)
- Testing requirements

## Security

Security is a top priority. Please review our [Security Policy](SECURITY.md) for:

- Supported versions
- Vulnerability reporting process
- Security best practices for samples

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

Code samples are licensed under the [MIT License](LICENSE-CODE).

Third-party notices: [ThirdPartyNotices](ThirdPartyNotices)

## Support

- **Documentation issues**: File a GitHub issue in this repository
- **Product support**: Visit [Microsoft Support](https://support.microsoft.com/)
- **Community**: [TechCommunity Virtualization](https://techcommunity.microsoft.com/t5/virtualization/bd-p/Virtualization)

---

Maintained by the Microsoft Virtualization Documentation Team
