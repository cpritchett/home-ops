# Contributing to home-ops

This is a personal homelab repository managed by Chad Pritchett. While external contributions are not expected, this guide documents the development workflow.

## Development Workflow

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

- Follow GitOps principles - changes to `kubernetes/apps/` only take effect after git commit/push
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
