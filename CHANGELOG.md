# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Comprehensive README.md with repository overview, quick start guides, and contribution guidelines
- SECURITY.md with vulnerability reporting process, supported versions, and security best practices for samples
- ARCHITECTURE.md with detailed component architectures, cross-cutting concerns, and technology stack
- .nvmrc for reproducible Node.js version pinning (v20.18.0)
- .github/dependabot.yml for automated weekly dependency updates (npm and GitHub Actions)
- Comprehensive CI workflow (.github/workflows/ci.yml) orchestrating all quality gates
- Enhanced markdown-lint.yml with proper Node.js version from .nvmrc
- Enhanced ps-script-analyzer.yml with GitHub Actions annotations
- Enhanced asp-net-blog-sample.yml with Docker Compose validation and environment validation jobs
- Strong password guidance in .env.example with complexity requirements and generation command

### Changed

- .markdownlint.json: Enabled meaningful linting rules (was disabling nearly all rules)
- package.json: Added test scripts and improved devDependencies
- .gitignore: Added .env, IDE files, and sensitive file patterns

### Security

- Removed weak default password (Password123) from .env.example
- Added secret scanning in CI workflow
- Added .gitignore validation for sensitive file patterns
- Documented production security requirements in SECURITY.md

## [1.0.0] - 2026-10-19

### Added

- Initial repository structure with virtualization documentation
- Hyper-V tools (Convert-WindowsImage, DiscreteDeviceAssignment, DumpEncryption, HyperVLogs, ic-update, Nested, root-memory-reserve)
- Windows Container samples (ASP.NET Blog Application with SQL Server)
- Documentation pipeline configuration (Open Publishing / DocFX)
- GitHub Actions workflows for markdown linting, PowerShell analysis, and schema validation
- Basic package.json with markdownlint-cli
- EditorConfig for consistent formatting
- MIT License and Third Party Notices

---

## Release Process

1. Update version in `package.json` (follows SemVer)
2. Update this CHANGELOG.md with release notes
3. Create Git tag: `git tag -a v<version> -m "Release v<version>"`
4. Push tag: `git push origin v<version>`
5. GitHub Actions will build and publish documentation
6. Create GitHub Release from tag with changelog excerpt

## Versioning Policy

- **Major** (X.0.0): Breaking changes to tool interfaces, schema changes, removed samples
- **Minor** (X.Y.0): New tools, new samples, new documentation sections, non-breaking enhancements
- **Patch** (X.Y.Z): Bug fixes, typo corrections, dependency updates, CI improvements

---

Generated with [Keep a Changelog](https://keepachangelog.com/) principles
