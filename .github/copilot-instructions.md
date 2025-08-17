# Chad's Home-Ops GitOps Repository

**ALWAYS** follow these instructions first. Only search for additional information or use other tools if these instructions are incomplete or found to be in error.

This is Chad Pritchett's homelab infrastructure repository - a GitOps-managed Kubernetes cluster running on Talos Linux with Flux CD, 1Password secret management, and comprehensive automation via Task runner.

## Essential Setup Commands

### Install Required Tools

```bash
# Install Task runner (automation engine)
wget https://github.com/go-task/task/releases/download/v3.44.0/task_linux_amd64.tar.gz
tar -xzf task_linux_amd64.tar.gz
sudo mv task /usr/local/bin/
rm task_linux_amd64.tar.gz

# Install validation tools
sudo apt-get update && sudo apt-get install -y shellcheck
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq
chmod +x /tmp/yq && sudo mv /tmp/yq /usr/local/bin/yq

# For complete workstation setup (macOS with Homebrew)
task workstation:brew  # Installs all tools from Brewfile

# For mise tool manager setup (alternative approach)
curl https://mise.run | sh
mise install  # Installs tools from .mise.toml
```

### Critical Branch Workflow

**NEVER WORK ON MAIN BRANCH** - this will break the GitOps workflow.

```bash
# ALWAYS start from updated main
git checkout main
git pull origin main
git checkout -b feat/your-feature-name

# Branch naming: feat/, fix/, chore/, docs/, refactor/
# Commit format: type(scope): description
```

## Working Effectively

### Discover Available Commands
```bash
# List all automation commands - 60+ available
task --list
```

### Bootstrap and Build Process

**TIMING**: Bootstrap operations take 5-15 minutes. **NEVER CANCEL** these commands.

```bash
# Generate cluster secrets (if setting up new cluster)
task talos:gen-secrets

# Apply node configurations (replace with actual IPs)
task talos:apply-config NODE=10.0.5.215 INSECURE=true
task talos:apply-config NODE=10.0.5.220 INSECURE=true  
task talos:apply-config NODE=10.0.5.100 INSECURE=true

# Bootstrap cluster (takes 10-15 minutes - NEVER CANCEL)
task bootstrap:talos-cluster NODE=10.0.5.215

# Deploy applications via GitOps (takes 5-10 minutes - NEVER CANCEL)
task bootstrap:apps
```

### Validation Commands

**ALWAYS** run these validation steps before committing changes:

```bash
# Validate YAML syntax (takes 1-2 seconds)
find kubernetes/ -name "*.yaml" -exec yq eval . {} \; >/dev/null
find talos/ -name "*.yaml" -exec yq eval . {} \; >/dev/null

# Validate shell scripts (takes 1-2 seconds)
find scripts/ -name "*.sh" -exec shellcheck {} \;

# Flux GitOps validation (takes 2-5 minutes - NEVER CANCEL)
docker run --rm -v $(pwd):/workspace ghcr.io/allenporter/flux-local:v7.5.6 \
  test --all-namespaces --enable-helm \
  --path /workspace/kubernetes/flux/cluster --verbose
```

### Essential Troubleshooting

```bash
# Fix most secret/connectivity issues (takes 30-60 seconds)
task k8s:sync-secrets

# Force Flux to reconcile changes from Git
task k8s:reconcile

# Debug storage issues
task k8s:browse-pvc CLAIM=pvc-name

# Clean up failed pods
task k8s:cleanse-pods
```

## Repository Structure

```
kubernetes/     # All applications defined as code (312 YAML files)
├─ apps/        # Applications by namespace
│  ├─ actions-runner-system/  # GitHub Actions runners
│  ├─ cert-manager/          # Certificate management
│  ├─ databases/            # PostgreSQL, Redis, etc.
│  ├─ default/              # Default namespace apps
│  ├─ external-secrets/     # 1Password secret management
│  ├─ flux-system/          # GitOps system
│  ├─ kube-system/          # Core Kubernetes components
│  ├─ media/                # Media stack (SABnzbd, etc.)
│  ├─ networking/           # Ingress, DNS, load balancing
│  ├─ observability/        # Grafana, Loki, Prometheus
│  ├─ openebs-system/       # Local storage provider
│  ├─ rook-ceph/            # Distributed storage
│  ├─ system-upgrade/       # System upgrade controller
│  └─ volsync-system/       # Backup and restore
├─ components/  # Reusable kustomize components  
└─ flux/        # Flux system configuration

talos/          # Node configurations (10 YAML files)
├─ static-configs/  # Per-node configurations
└─ node-mapping.yaml # Source of truth for nodes

bootstrap/      # Initial cluster setup scripts
scripts/        # Automation and setup scripts
.taskfiles/     # Task automation organized by domain
docs/           # Comprehensive documentation
```

## Key Technologies & Commands

### Task Categories (Use `task --list` to see all)

- **bootstrap:*** - Cluster and application setup
- **k8s:*** - Kubernetes cluster management  
- **talos:*** - Node management and configuration
- **volsync:*** - Backup and restore operations

### Critical GitOps Workflow

**IMPORTANT**: Changes to Kubernetes resources will NOT be applied until committed to Git and pushed to origin. Flux reconciles from the Git repository, not local filesystem changes.

```bash
# After making changes
git add .
git commit -m "feat(app): your change description"
git push origin your-branch-name
# Create PR for review and merge
```

## Validation Scenarios

### Complete End-to-End Testing

**ALWAYS** run through these scenarios after making changes:

1. **YAML Validation** (30 seconds):
   ```bash
   find kubernetes/ talos/ -name "*.yaml" -exec yq eval . {} \; >/dev/null
   ```

2. **Script Validation** (30 seconds):
   ```bash
   find scripts/ -name "*.sh" -exec shellcheck {} \;
   ```

3. **GitOps Validation** (2-3 minutes - NEVER CANCEL):
   ```bash
   docker run --rm -v $(pwd):/workspace ghcr.io/allenporter/flux-local:v7.5.6 \
     test --all-namespaces --enable-helm \
     --path /workspace/kubernetes/flux/cluster --verbose
   ```

4. **Secret Sync Test** (30-60 seconds):
   ```bash
   task k8s:sync-secrets
   ```

## Common Tasks and Timing

| Command | Duration | Never Cancel |
|---------|----------|--------------|
| `task bootstrap:talos-cluster` | 10-15 min | YES |
| `task bootstrap:apps` | 5-10 min | YES |
| `task k8s:sync-secrets` | 30-60 sec | NO |
| `find . -name "*.yaml" -exec yq eval . {} \;` | 1-2 sec | NO |
| `find scripts/ -name "*.sh" -exec shellcheck {} \;` | 1-2 sec | NO |
| flux-local validation | 2-3 min | YES |

## Documentation Reference

- **Setup Guide**: `docs/SETUP-GUIDE.md` - Complete cluster setup
- **Troubleshooting**: `docs/CLUSTER-TROUBLESHOOTING.md` - Problem resolution
- **YAML Standards**: `docs/YAML-HELM-TEMPLATING-GUIDE.md` - Template rules
- **1Password Setup**: `docs/1PASSWORD-SETUP.md` - Secret management
- **Claude Instructions**: `CLAUDE.md` - Detailed command reference

## YAML/Helm Standards

**CRITICAL**: Always quote Helm template expressions:
- ✅ `name: "{{ .Release.Name }}"`
- ❌ `name: {{ .Release.Name }}`

**CRITICAL**: NEVER replace template variables with hardcoded values:
- ✅ `imageName: ghcr.io/app:${VERSION}`
- ❌ `imageName: ghcr.io/app:1.2.3`

## What Does NOT Work

- **Direct kubectl commands**: Repository has no active cluster connection - use task commands instead
- **Manual secret management**: All secrets managed via 1Password - use task commands
- **Direct talosctl commands**: Use `task talos:*` commands instead
- **Manual Flux operations**: Use `task k8s:reconcile` and `task k8s:sync-secrets`
- **Working on main branch**: Will break GitOps workflow - always use feature branches
- **Hardcoded values in YAML**: Will break templating system - use variables and templates

## Common Failures and Solutions

### flux-local validation fails with errors
- **Expected**: flux-local may show failures in disconnected environments
- **Action**: Validate the structure is correct, ignore connection errors
- **Time**: Allow full 2-3 minutes for validation to complete

### Task commands fail with "op user get --me"
- **Cause**: Not logged into 1Password CLI
- **Solution**: Run `op signin` first (requires active cluster and 1Password)
- **Note**: Expected in disconnected environments

### Shell scripts fail shellcheck
- **Expected**: Style warnings (SC2162, SC2181) are normal and acceptable
- **Action**: Focus on syntax errors, ignore style warnings
- **Note**: Current scripts pass with minor style warnings

## Before Committing Changes

**MANDATORY** checklist:
1. ✅ Run YAML validation (find + yq)
2. ✅ Run shell script validation (shellcheck)  
3. ✅ Run flux-local validation (docker command)
4. ✅ Test secret sync (task k8s:sync-secrets)
5. ✅ Verify branch is NOT main
6. ✅ Follow conventional commit format
7. ✅ Push to origin and create PR

## Emergency Commands

```bash
# Nuclear option - completely rebuild app
task k8s:nuke-app APP=app-name NAMESPACE=namespace

# Reset cluster entirely (extreme cases only)
task talos:reset-cluster

# Force unlock backup repositories
task volsync:unlock
```

**Remember**: This is a production homelab system. Always test changes carefully and follow the GitOps workflow.