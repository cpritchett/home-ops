# PostgreSQL Bootstrap Guide

This guide covers setting up PostgreSQL database users for home-ops applications, including complete cluster reset scenarios.

## Quick Start

For a working PostgreSQL cluster that just needs database users:

```bash
# Bootstrap all required database users automatically
task bootstrap:postgres-users
```

This command will:

- Automatically discover all required database users from ExternalSecrets
- Create database users and databases
- Store passwords securely in 1Password
- Handle both new deployments and cluster resets

## When to Use

### After Cluster Reset

When you've rebuilt your PostgreSQL cluster from scratch, applications will fail to connect because their database users don't exist.

**Symptoms:**

- Apps stuck in `Init:Error` or `CrashLoopBackOff`
- PostgreSQL logs showing `role "appname" does not exist`
- ExternalSecrets syncing but apps can't authenticate

### Adding New Applications

When adding new applications that need PostgreSQL databases, the bootstrap script will automatically detect and create their users.

## How It Works

### Automatic Discovery

The script scans all ExternalSecrets in your cluster looking for patterns like:

- `APPNAME_POSTGRES_USER` fields
- `INIT_POSTGRES_USER` configurations

### Password Management

For each discovered application:

1. **Existing 1Password entry**: Uses the stored password
2. **Missing password**: Generates secure password and stores it in 1Password
3. **New application**: Creates complete 1Password entry with user and password

### Database Setup

For each application, creates:

- PostgreSQL user with secure password
- Database owned by that user
- Proper permissions for full database access

## Supported Applications

Currently auto-detected applications include:

- **autobrr** - Release automation
- **atuin** - Shell history sync
- **gatus** - Status monitoring
- **prowlarr** - Indexer management
- **radarr** - Movie management
- **sonarr** - TV show management

**Note**: The script automatically discovers new applications as you add them to your cluster.

## Manual Usage

### Check What Would Be Created

```bash
# See what users would be discovered (dry-run concept)
kubectl get externalsecrets -A -o yaml | grep -E "POSTGRES_USER.*}}" | grep -v SUPER
```

### Create Specific User Manually

```bash
# Connect to PostgreSQL directly
kubectl exec -it postgres-1 -n databases -c postgres -- psql -U postgres

# Create user and database
CREATE USER myapp WITH PASSWORD 'secure_password';
CREATE DATABASE myapp OWNER myapp;
GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp;
```

### Add User to 1Password

```bash
# Create new 1Password entry
op item create --vault homelab --title "myapp" --category database \
    "MYAPP_POSTGRES_PASS[password]=secure_password" \
    "MYAPP_POSTGRES_USER[text]=myapp"
```

## Troubleshooting

### Database Connection Failures

**Symptoms**: Apps showing `password authentication failed` in PostgreSQL logs

**Solution**: Run the bootstrap script to sync passwords:

```bash
task bootstrap:postgres-users
```

### New App Not Detected

**Check ExternalSecret**: Ensure your new application has the proper ExternalSecret pattern:

```yaml
data:
  MYAPP__POSTGRES__USER: "{{ .MYAPP_POSTGRES_USER }}"
  MYAPP__POSTGRES__PASSWORD: "{{ .MYAPP_POSTGRES_PASS }}"
  # or
  INIT_POSTGRES_USER: "{{ .MYAPP_POSTGRES_USER }}"
  INIT_POSTGRES_PASS: "{{ .MYAPP_POSTGRES_PASS }}"
```

### 1Password Entry Missing

**Automatic Fix**: The bootstrap script will create missing entries automatically.

**Manual Creation**: If you prefer to create entries manually:

```bash
op item create --vault homelab --title "appname" --category database \
    "APPNAME_POSTGRES_PASS[password]=$(openssl rand -base64 32 | cut -c1-25)" \
    "APPNAME_POSTGRES_USER[text]=appname"
```

### Script Prerequisites

Ensure you have:

- `kubectl` configured and connected to cluster
- `op` (1Password CLI) authenticated: `op user get --me`
- PostgreSQL cluster running: `kubectl get cluster postgres -n databases`

## Complete Cluster Recovery

For a total cluster rebuild scenario:

### 1. Restore PostgreSQL Cluster

```bash
# After Talos/Kubernetes is running
task bootstrap:apps  # This deploys PostgreSQL cluster
```

### 2. Wait for PostgreSQL Ready

```bash
# Check cluster status
kubectl get cluster postgres -n databases
# Should show: STATUS = "Cluster in healthy state"
```

### 3. Bootstrap Database Users

```bash
# Create all required users and databases
task bootstrap:postgres-users
```

### 4. Restart Application Pods

```bash
# Force apps to retry database connections
kubectl delete pods -A -l 'app.kubernetes.io/name in (atuin,autobrr,prowlarr,radarr,sonarr,gatus)'
```

### 5. Verify Connectivity

```bash
# Check for authentication errors
kubectl logs postgres-1 -n databases -c postgres --tail=20
# Should see successful connections, not "role does not exist" errors
```

## Integration with Cluster Bootstrap

The PostgreSQL bootstrap is integrated into the main cluster bootstrap process:

```bash
# Full cluster bootstrap includes PostgreSQL users
task bootstrap:apps

# PostgreSQL-specific bootstrap
task bootstrap:postgres-users
```

This ensures that after any cluster reset, your applications can immediately connect to their databases without manual intervention.

## Security Notes

- **Passwords**: All passwords are generated with high entropy (25 characters, alphanumeric)
- **Storage**: Passwords are stored only in 1Password vault "homelab"
- **Permissions**: Database users have full access only to their own database
- **Rotation**: To rotate passwords, delete the field from 1Password and re-run the bootstrap script

## Future Applications

When you add new applications to your cluster:

1. **Add ExternalSecret** with proper `APPNAME_POSTGRES_USER` pattern
2. **Run bootstrap script** - it will automatically detect and create the new user
3. **Deploy application** - it will find its database ready and waiting

No manual database setup required for new applications following the established patterns.
