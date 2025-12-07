# Contributing to home-ops

This is a personal homelab repository managed by Chad Pritchett. Most contributions come from AI agents (GitHub Copilot, Sentry/Seer, etc.) that create PRs based on issues and prompts.

## For AI Agents

**Required Reading:** `.github/copilot-instructions.md` contains mandatory workflow rules and architectural context.

### Quick Start Checklist

1. **Read context first:**
   - `.github/copilot-instructions.md` - GitOps workflow rules (MANDATORY)
   - `docs/` - Component-specific guides and troubleshooting
   - `Taskfile.yaml` - Available automation commands (`task --list`)

2. **Follow GitOps workflow:**
   - Always create feature branch (`type/scope-description`)
   - Never work on or commit to `main` branch
   - Changes to `kubernetes/apps/` only apply after commit+push (Flux reconciles from git)

3. **Use repository automation:**
   - Prefer `task` commands over raw kubectl/talosctl
   - Common: `task k8s:sync-secrets`, `task k8s:reconcile`, `task volsync:fix-stuck-app`

4. **Validate changes:**
   - Run relevant `task` commands to test
   - Verify Flux reconciliation for Kubernetes changes
   - Check for secrets leakage (use ExternalSecrets)

### Architecture Quick Reference

- **GitOps:** Flux CD manages all deployments from git
- **Cluster:** 3-node Talos Kubernetes (v1.31+)
- **CNI:** Cilium with eBPF
- **Storage:** Rook Ceph (distributed) + OpenEBS (local)
- **Secrets:** 1Password Connect + ExternalSecrets Operator
- **Backup:** VolSync for PVC snapshots

## Human Workflow

1. **Always work on a feature branch** - Never commit directly to main

   ```sh
   git checkout main
   git pull origin main
   git checkout -b type/scope-description
   ```

   Branch naming examples:
   - `feat/auth-improvements`
   - `fix/storage-mount-issue`
   - `docs/readme-update`
   - `chore/dependency-updates`

2. **Make your changes** following the repository guidelines in `.github/copilot-instructions.md`

3. **Commit with conventional commit format:**

   ```sh
   git add .
   git commit -m "type(scope): description"
   ```

   Examples:
   - `feat(media): add plex gpu transcoding`
   - `fix(storage): resolve PVC mount issues`
   - `docs(setup): update 1password configuration`

4. **Push to origin and create a PR:**

   ```sh
   git push origin feature-branch
   ```

5. **Merge via GitHub** after any CI checks pass

## Key Guidelines

- Follow GitOps principles: **Flux only reconciles from the git repository** – local filesystem changes to `kubernetes/apps/` will NOT be applied until they are committed and pushed. Always commit and push changes before expecting Flux to apply them.
- Use `task --list` to discover available automation commands
- Check `docs/` directory for detailed procedures before making infrastructure changes
- Never commit secrets directly - use 1Password ExternalSecrets
- Test changes with Flux reconciliation before merging

## Repository Structure

- `kubernetes/apps/` - Application deployments by namespace
- `talos/` - Talos node configurations  
- `bootstrap/` - Cluster initialization scripts
- `docs/` - Documentation and guides
- `.taskfiles/` - Task automation definitions
- `.github/copilot-instructions.md` - **AI agent workflow rules** (mandatory reading)
