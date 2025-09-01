# Contributing Incus Modules to ansible-truenas Fork

This document describes the new Incus-related modules created for TrueNAS SCALE 25.04+ that should be contributed to the [cpritchett/ansible-truenas](https://github.com/cpritchett/ansible-truenas) fork.

## New Modules Created

### 1. `truenas_incus_instance`

Manages Incus LXC containers and VMs on TrueNAS SCALE 25.04+

**Location:** `library/truenas_incus_instance.py`

**Features:**

- Create/delete Incus containers and VMs
- Start/stop/restart instances
- Configure CPU, memory limits
- Setup storage devices and network interfaces
- Port proxy configuration for unprivileged containers

**API Endpoints Used:**

- `/api/v2.0/virt/instance` - List/create instances
- `/api/v2.0/virt/instance/{id}` - Manage specific instance
- `/api/v2.0/virt/instance/{id}/start` - Start instance
- `/api/v2.0/virt/instance/{id}/stop` - Stop instance
- `/api/v2.0/virt/instance/{id}/restart` - Restart instance

### 2. `truenas_incus_exec`

Executes commands inside Incus instances

**Location:** `library/truenas_incus_exec.py`

**Features:**

- Execute commands in containers/VMs
- Support for creates/removes conditions
- Environment variable support
- Working directory (chdir) support
- Timeout configuration

**API Endpoints Used:**

- `/api/v2.0/virt/instance/{id}/exec` - Execute commands

## How to Contribute to Fork

1. **Clone your fork:**

   ```bash
   git clone https://github.com/cpritchett/ansible-truenas.git
   cd ansible-truenas
   git checkout -b feature/incus-support
   ```

2. **Create module directories:**

   ```bash
   mkdir -p plugins/modules
   ```

3. **Copy the modules:**

   ```bash
   cp /path/to/home-ops/infrastructure/pxe-bootstrap/library/truenas_incus_instance.py \
      plugins/modules/

   cp /path/to/home-ops/infrastructure/pxe-bootstrap/library/truenas_incus_exec.py \
      plugins/modules/
   ```

4. **Update module imports to use collection utilities:**

   In both modules, update the imports:

   ```python
   from ansible_collections.arensb.truenas.plugins.module_utils.common import (
       TrueNASModule,
       truenas_argument_spec
   )
   ```

5. **Add module documentation:**

   Create `docs/modules/truenas_incus_instance.md` and `docs/modules/truenas_incus_exec.md`

6. **Add integration tests:**

   ```yaml
   # tests/integration/targets/truenas_incus_instance/tasks/main.yml
   ---
   - name: Test container creation
     truenas_incus_instance:
       name: test-container
       state: present
       type: CONTAINER
       source:
         type: IMAGE
         alias: alpine/3.19

   - name: Test command execution
     truenas_incus_exec:
       name: test-container
       command: echo "Hello from container"
     register: exec_result

   - name: Verify output
     assert:
       that:
         - exec_result.stdout == "Hello from container"

   - name: Clean up test container
     truenas_incus_instance:
       name: test-container
       state: absent
   ```

7. **Update collection metadata:**

   Add to `meta/runtime.yml`:

   ```yaml
   requires_ansible: ">=2.10.8"
   plugin_routing:
     modules:
       truenas_incus_instance:
         redirect: arensb.truenas.truenas_incus_instance
       truenas_incus_exec:
         redirect: arensb.truenas.truenas_incus_exec
   ```

8. **Commit and push:**

   ```bash
   git add .
   git commit -m "feat: Add Incus support for TrueNAS SCALE 25.04+

   - Add truenas_incus_instance module for managing containers/VMs
   - Add truenas_incus_exec module for executing commands
   - Support for unprivileged containers with port proxying
   - Compatible with TrueNAS SCALE 25.04 (Fangtooth) and later"

   git push origin feature/incus-support
   ```

9. **Create PR to upstream:**
   - Create PR from your fork to upstream arensb/ansible-truenas
   - Reference TrueNAS SCALE 25.04 release notes
   - Note that Incus is experimental in 25.04, enterprise-ready in Goldeye (Oct 2025)

## Module Design Considerations

1. **API Compatibility:** These modules use the new `/virt/instance` endpoints introduced in TrueNAS SCALE 25.04

2. **Error Handling:** Modules handle the experimental nature of Incus by checking for feature availability

3. **Idempotency:** Both modules are idempotent - safe to run multiple times

4. **Check Mode:** Full support for Ansible check mode (`--check`)

## Testing the Modules

Before contributing, test locally:

```bash
# Test with your PXE infrastructure
cd infrastructure/pxe-bootstrap
ansible-playbook playbooks/deploy-matchbox.yml --check

# Test individual module
ansible -m truenas_incus_instance \
  -a "name=test state=present type=CONTAINER source={'type':'IMAGE','alias':'alpine/3.19'}" \
  -e "api_url=https://truenas.local/api/v2.0 api_key=YOUR_KEY" \
  localhost
```

## Future Enhancements

Consider adding these modules in future PRs:

- `truenas_incus_snapshot` - Manage instance snapshots
- `truenas_incus_network` - Manage Incus networks
- `truenas_incus_storage` - Manage Incus storage pools
- `truenas_incus_profile` - Manage Incus profiles

## Notes

- These modules require TrueNAS SCALE 25.04 or later
- Incus is marked "experimental" in 25.04
- Full enterprise support expected in TrueNAS "Goldeye" (October 2025)
- The modules use direct API calls as the TrueNAS middleware doesn't expose all Incus functionality yet
