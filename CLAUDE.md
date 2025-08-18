# 🚨 GITOPS WORKFLOW RULES - MANDATORY 🚨

**Chad Pritchett's home-ops GitOps repository - 3-node Talos Kubernetes cluster with Flux CD**

## BEFORE ANY CHANGES - EXECUTE THIS SEQUENCE:

```bash
git branch                                    # 1. Check current branch
git checkout main && git pull origin main    # 2. Switch to updated main
git checkout -b type/scope-description       # 3. Create feature branch
# Examples:
#   feat/auth-improvements
#   fix/storage-mount-issue
#   docs/readme-update
```

## ABSOLUTE PROHIBITIONS:

- 🔴 **NEVER work on main branch** - breaks GitOps workflow
- 🔴 **NEVER commit/push to main** - only merge via approved PRs
- 🔴 **NEVER bypass automation** - fix the automation, don't patch around it
- 🔴 **NEVER manually create PVCs/ExternalSecrets** - let VolSync/1Password do it

## GitOps Reality:

**Flux only deploys changes from the git repository – local modifications to `kubernetes/apps/` won't take effect until committed and pushed**

## Essential Commands

**Use `task --list` to discover all commands. ALWAYS prefer task commands over raw kubectl/talosctl.**

```bash
# Most common fixes
task k8s:sync-secrets                   # Fixes most ExternalSecret issues
task k8s:browse-pvc CLAIM=<name>        # Debug storage issues
task volsync:fix-stuck-app APP=<app>    # Fix stuck VolSync apps
task talos:pull-secrets                 # Sync certificates from 1Password
```

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

### GitOps Automation Principles (CRITICAL)

**NEVER MANUALLY CREATE OR PATCH RESOURCES AS WORKAROUNDS**: PVCs created by VolSync, ExternalSecrets, or other automation tools must NEVER be manually created or modified as "quick fixes". We fix the automation itself to reach eventual consistency, not bypass it with patches or hacks.

**ALWAYS FIX THE ROOT CAUSE**: When GitOps automation fails (VolSync, Flux, ExternalSecrets), troubleshoot and fix the automation system itself. Examples:

- VolSync restore failures → Trigger new restore operations, check snapshots, fix VolSync configuration
- ExternalSecret failures → Fix 1Password Connect, check secret references, sync secrets properly
- Flux reconciliation issues → Fix git repository state, check Flux controllers, resolve conflicts

**GitOps WORKFLOW INTEGRITY**: Maintain the integrity of automated systems. Manual interventions should only be diagnostic (describe, logs, events) or corrective to the automation (patch ReplicationDestination triggers, restart controllers), never replacement of automated processes.

**EXCEPTION - STUCK RESOURCES**: Stuck volumes and finalizers that prevent Flux and automation from functioning can be removed to enable GitOps to do its job. This includes:

- Removing finalizers from stuck PVCs that prevent deletion/recreation
- Deleting stuck pods that hold volume locks and prevent automation
- Clearing resource locks that block automated reconciliation
- Removing old/stale VolumeSnapshots that block new PVC creation from VolSync
- These interventions clear the path for automation, they don't replace it

### Git Branch Safety (CRITICAL)

**NEVER WORK ON MAIN BRANCH**: All changes must be made on feature branches and submitted via pull requests.

**ALWAYS START FROM UPDATED MAIN**: Before creating any new branch, ensure you're working from the latest main:

```bash
git checkout main
git pull origin main
git checkout -b type/scope-description
```

1. **ALWAYS check current branch first**: `git branch`
2. **If not on main, switch to main FIRST**: `git checkout main && git pull origin main`
3. **Create branch from updated main**: `git checkout -b type/scope-description`
4. **ABSOLUTELY NEVER commit directly to main** - this will break the GitOps workflow
5. **NEVER push changes to main** - only merge via approved pull requests
6. **Branch naming**: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`
7. **Commit format**: `type(scope): description`

**CRITICAL GitOps Requirement**: Changes to Kubernetes resources (YAML files in `kubernetes/apps/`) will NOT be applied by Flux until they are committed to a git branch and either merged to main or pushed to origin. Flux reconciles from the git repository, not local filesystem changes. Always commit and push changes before expecting Flux to apply them.

### YAML/Helm Standards

**CRITICAL**: Always quote Helm template expressions in YAML values:

- ✅ `name: "{{ .Release.Name }}"`
- ❌ `name: {{ .Release.Name }}`
- ✅ `host: "{{ .Release.Name }}.hypyr.space"`
- ❌ `host: {{ .Release.Name }}.hypyr.space`

**CRITICAL**: NEVER replace template variables with hardcoded values:

- ✅ `imageName: ghcr.io/cloudnative-pg/postgresql:${POSTGRESQL_VERSION}`
- ❌ `imageName: ghcr.io/cloudnative-pg/postgresql:17.5-bookworm`
- ✅ `secretKey: "{{ .Values.secretKey }}"`
- ❌ `secretKey: "hardcoded-secret-value"`

**Reason**: Hardcoding breaks the templating system, version management, and environment-specific configurations. Only hardcode values when explicitly necessary and documented.

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
