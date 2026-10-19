# Security Policy

## Supported Versions

We provide security updates for the following versions of this repository's samples and tools:

| Version | Supported          |
| ------- | ------------------ |
| Current (main branch) | ✅ Yes |
| Previous major release | ✅ Yes (6 months) |
| Older releases | ❌ No |

**Note**: This repository contains documentation and sample code. The samples
are reference implementations and not production-ready services. Users
adapting samples for production must conduct their own security hardening.

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

**Preferred**: Use GitHub Security Advisories (private reporting)

1. Go to the [Security tab](../../security) of this repository
2. Click "Report a vulnerability"
3. Fill in the details and submit

**Alternative**: Email [secure@microsoft.com](mailto:secure@microsoft.com) with:

- Repository name: `Virtualization-Documentation`
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 3 business days
- **Initial assessment**: Within 10 business days
- **Status updates**: Every 30 days until resolution
- **Credit**: We acknowledge reporters in advisories (unless anonymity requested)

## Security Best Practices for Samples

### Container Samples (`windows-container-samples/`)

**Never use default credentials in production:**

- The `.env.example` file contains example passwords — **always override** with strong, unique secrets
- Use Docker secrets or a secrets manager (Azure Key Vault, HashiCorp Vault, AWS Secrets Manager)
- Rotate credentials regularly

**Network security:**

- Samples use bridge networks for simplicity — use overlay networks with encryption in production
- Restrict published ports to required interfaces only
- Enable TLS for inter-service communication

**Image security:**

- Base images are pinned to specific tags — regularly rebuild to pick up security patches
- Scan images with `docker scout` or equivalent before deployment
- Use distroless or minimal base images where possible

### Hyper-V Tools (`hyperv-tools/`)

**PowerShell script execution:**

- Scripts require elevated privileges — review code before running
- Use `-WhatIf` and `-Confirm` parameters when available
- Sign scripts with a code-signing certificate in enterprise environments

**VHD(X) creation:**

- Validate source media integrity (checksums) before conversion
- Store generated VHDs in access-controlled locations
- Apply BitLocker encryption to VHDs containing sensitive data

### SQL Schema Samples (`windows-container-samples/ASP-NET-Blog-Application/db/`)

- Schema scripts create logins with default passwords — **change immediately** after deployment
- Use contained database users instead of SQL logins where possible
- Enable Transparent Data Encryption (TDE) for databases at rest
- Apply principle of least privilege for application database users

## Secure Development Practices

### For Contributors

1. **Never commit secrets** — API keys, passwords, certificates, connection strings
2. **Use `.env.example` pattern** — Document required secrets without values
3. **Validate all inputs** — PowerShell parameters, SQL scripts, Docker environment variables
4. **Follow least privilege** — Containers run as non-root; scripts request minimal permissions
5. **Keep dependencies current** — Dependabot alerts are monitored; update promptly

### CI/CD Security

Our GitHub Actions workflows:

- Run on GitHub-hosted runners (ephemeral, isolated)
- Use pinned action versions (SHA) where possible
- Store secrets in GitHub Actions secrets (not in workflow files)
- Fail on security linting violations (PSScriptAnalyzer, markdownlint)

## Known Limitations

| Area | Limitation | Mitigation |
|------|------------|------------|
| ASP.NET Blog Sample | Uses SQL Server `sa` account | Use dedicated low-privilege user in production |
| Convert-WindowsImage | Requires admin/Windows | Run in isolated build environment |
| Docker Compose samples | Default bridge network | Use production orchestrator (Kubernetes, Swarm) |
| Documentation | May reference deprecated features | Check publish date; cross-reference with current docs |

## Compliance

Samples align with:

- [Microsoft Security Development Lifecycle (SDL)](https://www.microsoft.com/en-us/securityengineering/sdl)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker) (container samples)
- [NIST SP 800-53](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final) controls (where applicable)

## Contact

For security questions not related to vulnerability reporting:

- Open a [GitHub Discussion](../../discussions) with the `security` label
- Tag `@microsoft/virtualization-docs-security` in issues

---

Last updated: 2026-10-19
Policy version: 1.0
