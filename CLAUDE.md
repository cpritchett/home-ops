# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this home-ops GitOps repository.

## Repository Overview

**Type**: Home-ops GitOps repository managing a 3-node Talos Linux Kubernetes cluster with Flux CD
**Key Technologies**: Talos Linux, Kubernetes, Flux CD, 1Password secrets management
**Documentation**: See `docs/SETUP-GUIDE.md` for complete setup instructions and `docs/` directory for user-facing documentation

## Essential Task Commands

**ALWAYS prefer task commands** over raw kubectl/talosctl commands when available. Use `task --list` to discover commands.

### Common Operations

```bash
# Cluster status and troubleshooting
task k8s:sync-secrets                   # Force sync ExternalSecrets (fixes most issues)
task k8s:browse-pvc CLAIM=<name>        # Debug storage by mounting PVC
task k8s:cleanse-pods                   # Clean up failed/pending pods

# Secret management workflow
task talos:pull-secrets                 # Pull from 1Password (what nodes use)
task talos:push-secrets                 # Push to 1Password (updates nodes)

# Bootstrap operations (all under bootstrap: prefix)
task bootstrap:talos-cluster NODE=<ip>  # Bootstrap Talos control plane
task bootstrap:apps                     # Deploy Kubernetes apps
task bootstrap:app-secrets              # Bootstrap API keys
task bootstrap:postgres-users           # Bootstrap PostgreSQL users
task bootstrap:cloudflare-tunnel        # Setup external access
```

### Troubleshooting Patterns

1. **Secret issues**: Always run `task k8s:sync-secrets` first (auto-fixes 1Password Connect)
2. **Storage issues**: Use `task k8s:browse-pvc CLAIM=<name>` to debug PVCs
3. **Certificate mismatches**: Run `task talos:pull-secrets` to sync from 1Password
4. **Full documentation**: See `docs/CLUSTER-TROUBLESHOOTING.md`

## Key Configuration Details

### Cluster Variables (Taskfile.yaml)

- **CONTROL_PLANE_ENDPOINT**: `https://homeops.hypyr.space:6443`
- **TALOS_ENDPOINTS**: `10.0.5.215,10.0.5.220,10.0.5.100`
- **OP_VAULT**: `homelab` (1Password vault)
- **Node mapping**: `talos/node-mapping.yaml` (source of truth)

### Architecture Notes

- **CNI**: Cilium with eBPF
- **Storage**: Rook Ceph (distributed) + OpenEBS (local at `/var/mnt/local-storage`)
- **Secrets**: 1Password Connect with ExternalSecrets
- **GitOps**: Flux CD manages all applications

## Development Workflow Rules

### Git Branch Safety (CRITICAL)

1. **ALWAYS check current branch first**: `git branch`
2. **If on main, create branch IMMEDIATELY**: `git checkout -b type/scope-description`
3. **NEVER commit directly to main**
4. **Branch naming**: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`
5. **Commit format**: `type(scope): description`

### YAML/Helm Standards

**CRITICAL**: Always quote Helm template expressions in YAML values:

- ✅ `name: "{{ .Release.Name }}"`
- ❌ `name: {{ .Release.Name }}`
- ✅ `host: "{{ .Release.Name }}.hypyr.space"`
- ❌ `host: {{ .Release.Name }}.hypyr.space`

See `docs/YAML-HELM-TEMPLATING-GUIDE.md` for complete rules.

### Task Command Priority

- **Secret sync issues**: `task k8s:sync-secrets`
- **Storage debugging**: `task k8s:browse-pvc CLAIM=name`
- **Cluster bootstrap**: Use `bootstrap:*` commands, not individual steps
- **Node management**: Prefer `talos:*` commands over raw talosctl

## File Organization

```
kubernetes/apps/        # Applications by namespace
bootstrap/              # Initial cluster setup scripts
talos/                  # Node configurations
docs/                   # User-facing documentation
scripts/                # Automation scripts
```

## External References

- **Setup Guide**: `docs/SETUP-GUIDE.md`
- **1Password Setup**: `docs/1PASSWORD-SETUP.md`
- **Troubleshooting**: `docs/CLUSTER-TROUBLESHOOTING.md`
- **PostgreSQL Bootstrap**: `docs/POSTGRESQL-BOOTSTRAP.md`
- **YAML Guidelines**: `docs/YAML-HELM-TEMPLATING-GUIDE.md`

## When Working on This Repository

1. **Check branch status first** (`git branch`)
2. **Use task commands** when available (`task --list`)
3. **Check docs/ for detailed procedures** rather than asking
4. **Follow conventional commits** spec for all changes
5. **Test with secret sync** after ExternalSecret changes (`task k8s:sync-secrets`)
6. **Reference relevant docs** when explaining procedures to users
