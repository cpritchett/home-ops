# Renovate Bot Permission Issues Troubleshooting Guide

## Issues Identified

The Renovate dashboard is reporting these specific problems:

1. **"Cannot access vulnerability alerts. Please ensure permissions have been granted."**
2. **"Package lookup failures"**

## Root Cause Analysis

### Issue 1: Cannot Access Vulnerability Alerts

This error occurs when the GitHub App used by Renovate lacks the necessary permissions to read repository vulnerability alerts.

**Required configurations:**

1. **GitHub App Permissions** - The Renovate GitHub App must have:
   - `Vulnerability alerts: Read` permission
   - `Repository security events: Read` permission

2. **Repository Security Settings** must be enabled:
   - Security & analysis → Dependency graph ✅
   - Security & analysis → GitHub vulnerability alerts ✅
   
   **Note:** These are GitHub platform features (not Dependabot-specific) that Renovate uses to detect vulnerabilities.

3. **Renovate Configuration** should include:
   ```json
   {
     "vulnerabilityAlerts": {
       "enabled": true
     }
   }
   ```

### Issue 2: Package Lookup Failures

This error typically occurs when Renovate cannot access package registries due to authentication or permission issues.

**Common causes:**
- Missing or incorrect GitHub token permissions
- Missing `packages:read` permission for GitHub Packages
- Incorrect host rules configuration for private registries

## Investigation Steps

### Step 1: Check GitHub App Configuration

1. Go to GitHub Settings → Developer settings → GitHub Apps
2. Find your Renovate app installation
3. Verify these permissions are enabled:
   - [ ] Vulnerability alerts: Read
   - [ ] Repository security events: Read
   - [ ] Packages: Read (if using GitHub Packages)
   - [ ] Contents: Read
   - [ ] Metadata: Read
   - [ ] Pull requests: Write

### Step 2: Check Repository Security Settings

1. Go to repository Settings → Security & analysis
2. Ensure these are enabled:
   - [ ] Dependency graph (required for Renovate)
   - [ ] GitHub vulnerability alerts (required for Renovate)
   
   **Note:** These are GitHub platform features that Renovate uses to detect security issues. This is separate from Dependabot, which is GitHub's native dependency update tool.

### Step 3: Verify Bot Secrets Configuration

Check that the GitHub Actions secrets are properly configured:

```bash
# These secrets should exist in repository settings
BOT_APP_ID=<your-app-id>
BOT_APP_PRIVATE_KEY=<your-private-key>
```

### Step 4: Check Renovate Configuration

Examine `.renovaterc.json5` for proper vulnerability alert configuration:

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "vulnerabilityAlerts": {
    "enabled": true
  },
  // ... other configuration
}
```

## Fix Procedures

### Fix 1: Update GitHub App Permissions

1. Go to the GitHub App settings
2. Edit permissions to include:
   - Vulnerability alerts: Read
   - Repository security events: Read
   - Packages: Read (for package lookup issues)
3. Save the configuration
4. Re-install or update the app installation on the repository

### Fix 2: Enable Repository Security Features

1. Navigate to Repository Settings → Security & analysis
2. Enable "Dependency graph" (required for Renovate vulnerability detection)
3. Enable "GitHub vulnerability alerts" (required for Renovate vulnerability detection)

**Note:** These are GitHub platform features that Renovate uses, separate from Dependabot which is GitHub's native dependency update tool.

### Fix 3: Verify Secrets are Current

Run the GitHub bot setup script to ensure secrets are properly stored:

```bash
./scripts/setup-github-bot.sh
```

### Fix 4: Test Configuration

Trigger a manual Renovate run to test the fixes:

1. Go to Actions tab in GitHub
2. Find "Renovate" workflow
3. Click "Run workflow"
4. Monitor the logs for the resolved issues

## Verification

After applying fixes, verify the issues are resolved:

1. **Check Renovate Dashboard**: Look for the absence of warning messages
2. **Review Workflow Logs**: Ensure no WARN messages about vulnerability alerts
3. **Verify Package Detection**: Confirm that dependency updates are being detected
4. **Test Functionality**: Ensure PRs are being created for available updates

## Related Documentation

- [Renovate Security and Permissions](https://docs.renovatebot.com/security-and-permissions/)
- [GitHub App Permissions](https://docs.github.com/en/developers/apps/managing-github-apps/editing-a-github-apps-permissions)
- [GitHub Vulnerability Alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts)

**Note:** While the last link references Dependabot alerts, Renovate uses the same GitHub vulnerability detection infrastructure. These are platform features, not tool-specific.

## Common Mistakes to Avoid

1. **Forgetting to save GitHub App permission changes**
2. **Not re-installing the app after permission changes**
3. **Disabling security features that Renovate requires**
4. **Using personal access tokens instead of GitHub App authentication**
5. **Missing package registry authentication for private packages**