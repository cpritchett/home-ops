# NFS Share Troubleshooting Guide

## Problem Summary

Kubernetes applications were unable to see existing content through NFS mounts, despite proper basic connectivity. The issue was complex NFSv4 ACL inheritance and user mapping conflicts.

## Root Cause Analysis

1. **Complex NFSv4 ACLs**: ZFS child datasets inherited complex NFSv4 ACLs that prevented proper NFS directory enumeration
2. **User Mapping Conflicts**: NFS `maproot` settings conflicted with container UIDs, causing visibility issues
3. **Child Dataset Issues**: Separate ZFS datasets had different ACL configurations

## The Working Solution

### 1. Create Clean ZFS Dataset with Optimal Settings

```bash
# Create new dataset
zfs create pool/dataset

# Set performance-optimized properties
zfs set recordsize=1M pool/dataset      # Optimal for large files
zfs set compression=lz4 pool/dataset    # Fast compression with good ratio
zfs set atime=off pool/dataset          # Disable access time updates for performance
zfs set xattr=sa pool/dataset           # Store extended attributes efficiently
zfs set acltype=posix pool/dataset      # Use simple POSIX ACLs instead of NFSv4
```

### 2. Create Proper Directory Structure

```bash
# Root directory with proper ownership
chown appuser:appgroup /mnt/pool/dataset
chmod 755 /mnt/pool/dataset

# Create directory structure
mkdir -p /mnt/pool/dataset/{content,downloads,temp}

# Set ownership and permissions
chown -R appuser:appgroup /mnt/pool/dataset
chmod -R 755 /mnt/pool/dataset
```

### 3. Configure NFS Export (No User Mapping)

```bash
# Create NFS export with NO user mapping
# Example for TrueNAS:
midclt call sharing.nfs.create '{
  "path": "/mnt/pool/dataset",
  "networks": ["10.0.0.0/24"],
  "maproot_user": null,
  "maproot_group": null,
  "mapall_user": null,
  "mapall_group": null,
  "ro": false,
  "enabled": true
}'

# Restart NFS service
service nfs restart
```

### 4. Migrate Content with Proper Ownership

**Content Migration:**

```bash
sudo rsync -av \
  --chown=appuser:appgroup \
  --no-perms \
  --chmod=D755,F644 \
  /source/path/ \
  /destination/path/
```

**What each flag does:**

- `-av`: Archive mode with verbose output
- `--chown=appuser:appgroup`: Set ownership during copy (prevents root ownership)
- `--no-perms`: Don't preserve source permissions (prevents ACL issues)
- `--chmod=D755,F644`: Set consistent permissions (dirs=755, files=644)

**Example usage:**

```bash
# Basic migration
sudo rsync -av --chown=appuser:appgroup --no-perms --chmod=D755,F644 \
  /source/path/ \
  /destination/path/

# Parallel migrations with tmux
tmux new-session -d -s 'migrate-content' 'sudo rsync -av --chown=appuser:appgroup --no-perms --chmod=D755,F644 /source/ /destination/'

# Check progress
tmux list-sessions
tmux attach-session -t migrate-content
# Press Ctrl+B then D to detach
```

## Key Benefits of This Solution

1. **Simple Permissions**: POSIX ACLs are predictable and work reliably with NFS
2. **No User Mapping**: Eliminates complex mapping conflicts
3. **Optimal Performance**: ZFS tuned for large media files with lz4 compression
4. **Hardlinks Work**: Single mount point preserves filesystem semantics
5. **Atomic Moves Work**: Fast moves between directories for content organization
6. **Consistent Ownership**: All content has proper ownership

## Verification Tests

After setup, verify functionality:

```bash
# Test content visibility
kubectl exec -n namespace pod-name -- ls -la /data/

# Test hardlink creation
kubectl exec -n namespace pod-name -- sh -c '
  echo "test" > /data/downloads/test.txt
  ln /data/downloads/test.txt /data/content/hardlink.txt
  ls -li /data/downloads/test.txt /data/content/hardlink.txt
'

# Test atomic moves
kubectl exec -n namespace pod-name -- sh -c '
  echo "move test" > /data/temp/move.txt
  mv /data/temp/move.txt /data/content/moved.txt
  ls -la /data/content/moved.txt
'
```

## What NOT to Do

1. **Don't use complex NFSv4 ACLs** - They cause enumeration issues
2. **Don't use NFS user mapping** - Creates UID conflicts with containers
3. **Don't mix mount points** - Breaks hardlinks and atomic moves
4. **Don't preserve complex permissions** - Use consistent simple permissions

## Troubleshooting

If content isn't visible:

1. Check ownership: `ls -la` should show correct user:group IDs
2. Check permissions: Directories should be `755`, files `644`
3. Restart pods to refresh NFS mounts
4. Verify NFS export has no user mapping set

## Performance Notes

- **recordsize=1M**: Optimal for large files, reduces fragmentation
- **compression=lz4**: Fast compression with minimal CPU overhead
- **atime=off**: Eliminates unnecessary disk writes for access times
- **POSIX ACLs**: Simpler and faster than NFSv4 for basic permissions
