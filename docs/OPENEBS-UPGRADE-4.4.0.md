# OpenEBS 4.3.3 to 4.4.0 Upgrade Analysis

## Summary

The upgrade from OpenEBS 4.3.3 to 4.4.0 in this repository is **safe and correctly configured**. The pre-upgrade hook is intentionally disabled, which is the recommended approach to avoid known issues.

## Pre-Upgrade Hook Status

### Current Configuration

The HelmRelease configuration at `kubernetes/apps/openebs-system/openebs/app/helmrelease.yaml` has the following settings:

```yaml
install:
  disableHooks: true
  remediation:
    retries: -1
upgrade:
  cleanupOnFail: true
  disableHooks: true
  remediation:
    retries: 3
```

**Key Point:** `disableHooks: true` is set for both install and upgrade operations.

### What This Means

- **No pre-upgrade hook runs**: The OpenEBS Helm chart includes a pre-upgrade hook that performs validation checks before upgrading. By setting `disableHooks: true`, this hook is completely bypassed.
- **This is intentional and recommended**: The pre-upgrade hook has known issues in the OpenEBS community (see references below).

### Why Disable the Pre-Upgrade Hook?

The OpenEBS pre-upgrade hook has several documented issues:

1. **Resource Conflicts**: The hook creates cluster-scoped resources (ServiceAccount, ClusterRole) named `openebs-pre-upgrade-hook`. On subsequent upgrades, these resources may not be cleaned up properly, causing failures with errors like:
   ```
   clusterroles.rbac.authorization.k8s.io "openebs-pre-upgrade-hook" already exists
   serviceaccounts "openebs-pre-upgrade-hook" already exists
   ```

2. **Limited Customization**: Until recently, the hook didn't support:
   - ImagePullSecrets for private registries
   - Node tolerations for tainted nodes
   - Resource limits/requests

3. **Flux CD Compatibility**: When using Flux CD with `disableHooks: true`, Flux manages the upgrade process more reliably without the hook interfering.

## Upgrade Changes in 4.4.0

The only change made by the upgrade commit (042616e) was:

```diff
   ref:
-    tag: 4.3.3
+    tag: 4.4.0
```

### Key Features in OpenEBS 4.4.0

According to the [official release notes](https://github.com/openebs/openebs/releases/tag/v4.4.0):

#### LocalPV LVM (Relevant to this cluster)
- **Snapshot restore**: Support for restoring snapshots to volumes
- **ThinPool space reclamation**: Automatic cleanup of thinpool LV after deleting the last thin volume
- **Improved scheduling**: Better thinpool statistics and space awareness

#### LocalPV Hostpath (Relevant to this cluster)
- Maintenance updates and bug fixes

#### LocalPV ZFS
- Go runtime updated to 1.24
- Improved resource management via values.yaml
- Fixed encryption parameter handling in clones

#### Mayastor (Not used in this cluster)
- DiskPool expansion support
- Various HA and rebuild improvements

## Cluster Configuration

This cluster uses:
- **LocalPV Hostpath**: Enabled (primary storage for `/var/mnt/local-storage`)
- **LocalPV LVM**: Disabled
- **LocalPV ZFS**: Disabled  
- **Mayastor**: Disabled

The values configuration shows:
```yaml
values:
  localpv-provisioner:
    localpv:
      basePath: /var/mnt/local-storage
      analytics:
        enabled: false
    hostpathClass:
      enabled: true
      name: openebs-hostpath
      isDefaultClass: false
```

## Upgrade Safety Assessment

✅ **Safe to proceed** because:

1. **No breaking changes** for LocalPV Hostpath users
2. **Pre-upgrade hook is disabled**, avoiding known issues
3. **Flux CD manages the upgrade** with proper retry logic (`retries: 3`)
4. **OpenEBS 4.4.0 is a minor version** with backward compatibility
5. **Storage path unchanged**: `/var/mnt/local-storage` remains the same

## Known Issues in 4.4.0

From the official release notes, the only relevant known issue is:

- **Controller Pod Restart on Single Node Setup**: After upgrading, single node setups may face issues where the controller pod does not enter the Running state due to changes in the controller manifest (now a Deployment) and missing affinity rules.
  - **Workaround**: Delete the old controller pod to allow the new pod to be scheduled correctly.
  - **Impact on this cluster**: This is a 3-node cluster, so this issue does not apply.

## Post-Upgrade Monitoring

After the upgrade is applied by Flux, monitor:

1. **HelmRelease status**:
   ```bash
   kubectl get helmrelease -n openebs-system openebs
   flux reconcile helmrelease openebs -n openebs-system
   ```

2. **OpenEBS controller pods**:
   ```bash
   kubectl get pods -n openebs-system
   ```

3. **Storage classes**:
   ```bash
   kubectl get sc openebs-hostpath
   ```

4. **Existing PVCs** (should remain healthy):
   ```bash
   kubectl get pvc -A | grep openebs-hostpath
   ```

## References

- [OpenEBS 4.4.0 Release Notes](https://github.com/openebs/openebs/releases/tag/v4.4.0)
- [OpenEBS Upgrade Documentation](https://openebs.io/docs/user-guides/upgrade)
- [Pre-upgrade hook issue #4085](https://github.com/openebs/openebs/issues/4085)
- [Pre-upgrade hook toleration issue #3798](https://github.com/openebs/openebs/issues/3798)
- [Pre-upgrade hook imagePullSecrets issue #3892](https://github.com/openebs/openebs/issues/3892)

## Conclusion

The pre-upgrade hook is **not being removed** by this upgrade—it has been intentionally disabled since the initial deployment by setting `disableHooks: true` in the HelmRelease configuration. This is the recommended approach when using Flux CD to manage OpenEBS upgrades.

The upgrade to 4.4.0 is safe to proceed and only changes the chart version tag. No configuration changes are needed, and the disabled hooks setting should remain as-is.
