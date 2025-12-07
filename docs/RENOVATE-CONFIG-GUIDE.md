# Renovate Configuration Guide

This document explains the Renovate configuration for the home-ops repository and the latest best practices implemented.

## Overview

The Renovate bot automatically monitors and updates dependencies across the entire repository, including:
- Docker container images
- Helm charts
- GitHub Actions
- Kubernetes manifests
- Tool versions in `.mise.toml`
- Grafana dashboards

## Configuration Structure

The configuration is modular, with separate files for different concerns:

```
.renovaterc.json5              # Main configuration
.renovate/
├── allowedVersions.json5      # Version constraints (e.g., PostgreSQL <=17)
├── autoMerge.json5            # Auto-merge rules for trusted updates
├── customManagers.json5       # Custom regex managers for special formats
├── grafanaDashboards.json5    # Grafana dashboard update handling
├── groups.json5               # Dependency grouping rules
├── labels.json5               # PR labeling configuration
├── packageRules.json5         # General package update rules
├── semanticCommits.json5      # Semantic commit message formatting
└── talosFactory.json5         # Talos installer image handling
```

## Key Features

### 1. Dependency Pinning

**What it does**: Pins exact versions and digests for dependencies to ensure reproducibility and security.

- **Docker Images**: All Docker images are pinned to specific digests (e.g., `image@sha256:abc123...`)
- **GitHub Actions**: Actions are pinned to commit SHAs for security
- **Version Ranges**: Most dependencies use exact versions rather than ranges

**Configuration**:
```json5
extends: [
  ":pinAllExceptDigests",
  "helpers:pinGitHubActionDigests"
],
pinDigests: true
```

### 2. Vulnerability Detection

**What it does**: Integrates multiple vulnerability databases to detect and prioritize security issues.

- **GitHub Vulnerability Alerts**: Enabled via `vulnerabilityAlerts.enabled`
- **OSV Database**: Enabled via `osvVulnerabilityAlerts`
- **OpenSSF Scorecard**: Enabled via `security:openssf-scorecard` preset

**Security Labels**: Renovate automatically labels PRs with vulnerability fixes using its built-in detection system.

### 3. Intelligent Grouping

**What it does**: Groups related dependencies together to reduce PR noise and ensure coordinated updates.

**Example Groups**:
- **Kubernetes and Talos**: Updates to Kubernetes, Talos, and related tools are grouped
- **Monitoring Stack**: Kube-Prometheus-Stack, Prometheus, Grafana, and Alertmanager
- **Home Automation**: Home Assistant, Zigbee2MQTT, and Mosquitto
- **PostgreSQL**: All PostgreSQL-related images and charts

See `.renovate/groups.json5` for the complete list.

### 4. Smart Auto-Merge

**What it does**: Automatically merges trusted, low-risk updates to reduce manual work.

**Auto-merge enabled for**:
- Patch updates from trusted registries (after 3-day stability period)
- Digest updates for trusted container images
- Minor/patch updates to GitHub Actions from `actions/` and `renovatebot/` orgs
- Grafana dashboard updates

**Auto-merge DISABLED for**:
- Major version updates (require manual review)
- Updates with high/critical security vulnerabilities

### 5. Release Stability

**What it does**: Waits for new releases to stabilize before creating PRs.

**Minimum Release Ages**:
- Major updates: 7 days (14 days for critical infrastructure)
- Minor updates: 3 days
- Patch updates: 1 day
- Kubernetes/Talos updates: 3 days

### 6. Enhanced PR Descriptions

**What it does**: PRs include rich information to help with review decisions.

**Information included**:
- Release notes and changelogs
- Version comparison (old → new)
- Security vulnerability data (when applicable)
- Dependency dashboard links

**Configuration**:
```json5
fetchChangeLogs: "pr",
dependencyDashboardHeader: "This issue lists Renovate updates and detected dependencies..."
```

### 7. Priority Management

**What it does**: Prioritizes updates based on type and security impact.

**Priority Levels**:
1. Security updates (highest priority)
2. Production dependencies
3. Infrastructure components
4. Development dependencies (lowest priority)

## Package Rule Highlights

### Critical Infrastructure Protection

Components like Cilium, Rook-Ceph, Cert-Manager, and External Secrets have:
- Extended stability periods (14 days for major updates)
- Required approval for major updates via dependency dashboard
- Higher scrutiny before merging

### Docker Image Handling

- All Docker images have digest pinning enabled
- Images are updated when new tags OR new digests are available
- Trusted registries (ghcr.io, quay.io) get faster auto-merge for patches

### GitHub Actions Security

- All actions are pinned to commit SHAs (not tags) for security
- Actions from trusted orgs (actions/, renovatebot/) auto-merge faster
- Other actions wait 3 days before auto-merge

### Tool Version Management

Tools defined in `.mise.toml` are tracked and updated:
- `talosctl`, `kubectl`, `flux2` versions tracked via custom managers
- `TALOS_VERSION` and `KUBERNETES_VERSION` environment variables updated
- Changes grouped with related Kubernetes/Talos updates

## Custom Managers

### 1. Annotated Dependencies

Detects dependencies marked with special comments:

```yaml
# renovate: datasource=github-releases depName=kubernetes/kubernetes
version: v1.29.1
```

### 2. Mise Tool Versions

Tracks tool versions in `.mise.toml`:

```toml
TALOS_VERSION = "v1.11.0"
kubectl = "1.34.2"
```

### 3. Grafana Dashboards

Automatically updates Grafana dashboard revisions from grafana.com.

## Labels and Organization

PRs are automatically labeled with:

**Update Type Labels**:
- `type/major`, `type/minor`, `type/patch`, `type/digest`

**Datasource Labels**:
- `renovate/container` (Docker images)
- `renovate/helm` (Helm charts)
- `renovate/github-action` (GitHub Actions)
- `renovate/github-release` (GitHub releases)

**Category Labels**:
- `renovate/kubernetes` (Kubernetes/Talos)
- `renovate/infrastructure` (Core infrastructure)
- `renovate/tooling` (CLI tools from mise)
- `security` (Security vulnerabilities)

## Semantic Commits

All Renovate commits follow conventional commit format:

**Format**: `type(scope): description (old → new)`

**Examples**:
- `feat(container): update image nginx (1.25.0 → 1.25.1)`
- `fix(helm): update chart cert-manager (1.12.0 → 1.12.1)`
- `chore(container): update image postgres digest (abc123 → def456)`

**Commit Types**:
- `feat`: Major and minor version updates
- `fix`: Patch version updates
- `chore`: Digest updates
- `ci`: GitHub Actions updates

## Dependency Dashboard

The dependency dashboard is a GitHub issue that provides:
- Overview of all pending updates
- Ability to trigger updates manually
- Status of auto-merge and approval requirements
- Links to release notes and changelogs

Access it at: **Issues** → **Renovate Dashboard 🤖**

## Best Practices

### When to Approve Major Updates

Consider these factors before approving a major update:
1. **Breaking Changes**: Review the changelog for breaking changes
2. **Test Coverage**: Ensure adequate test coverage exists
3. **Rollback Plan**: Have a rollback strategy ready
4. **Stability**: Wait for the configured minimum release age
5. **Dependencies**: Check if other components need updates

### Managing PR Volume

If you're getting too many PRs:
1. **Check Grouping**: Ensure related dependencies are grouped
2. **Adjust Auto-merge**: Consider enabling auto-merge for more update types
3. **Increase Stability Periods**: Extend `minimumReleaseAge` for components
4. **Use Dependency Dashboard**: Batch approve multiple updates at once

### Security Updates

Security updates should be prioritized:
1. They're automatically labeled with `security`
2. They bypass auto-merge for manual review
3. Review the vulnerability details before merging
4. Consider if immediate update is needed vs. waiting for stability

## Validation

The configuration is validated using `renovate-config-validator`:

```bash
npx renovate-config-validator
```

All configurations pass validation and use the latest Renovate schema.

## Migration Notes

Recent updates include:
- Migrated from `managerFilePatterns` to `fileMatch` for custom managers
- Replaced deprecated `prTitle` with `commitMessageTopic`
- Added new presets: `:pinAllExceptDigests`, `security:openssf-scorecard`
- Enhanced vulnerability detection with OSV database integration

## Troubleshooting

### No PRs Being Created

1. Check the Renovate Dashboard issue for pending updates
2. Verify GitHub App permissions are correct
3. Check workflow logs for errors
4. Ensure repository secrets are configured

### Too Many PRs

1. Review and adjust `prConcurrentLimit` (currently 10)
2. Enable more auto-merge rules
3. Increase `minimumReleaseAge` for update types
4. Add more dependency groups

### Auto-merge Not Working

1. Verify branch protection rules allow auto-merge
2. Check that update matches auto-merge criteria
3. Review `ignoreTests` settings
4. Ensure minimum release age has passed

## Additional Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Dependency Dashboard Guide](https://docs.renovatebot.com/key-concepts/dashboard/)
- [Security Best Practices](https://docs.renovatebot.com/best-practices/)

## Support

For issues specific to this repository:
1. Check `docs/RENOVATE-TROUBLESHOOTING.md`
2. Review GitHub Actions workflow logs
3. Check the Renovate Dashboard issue for status
4. Open an issue in this repository
