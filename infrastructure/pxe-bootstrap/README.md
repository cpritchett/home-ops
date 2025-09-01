# PXE Bootstrap Infrastructure

This directory contains Ansible playbooks and roles to deploy a complete PXE boot infrastructure on TrueNAS SCALE 25.04+ using Incus containers.

## Overview

The PXE infrastructure enables zero-touch provisioning of:

- **Talos Linux** nodes for Kubernetes
- **Proxmox VE** hypervisor nodes
- Automatic fallback to local disk for unknown systems

## Architecture

```
┌─────────────────────┐
│   DHCP Gateway      │
│  next-server: →     │───────┐
└─────────────────────┘       │
                              ▼
┌──────────────────────────────────────────┐
│         TrueNAS SCALE 25.04              │
│                                          │
│  ┌────────────────────────────────┐     │
│  │   Incus LXC Container           │     │
│  │   "matchbox"                    │     │
│  │                                 │     │
│  │  - Matchbox (HTTP/gRPC)         │     │
│  │  - TFTP Server (dnsmasq)        │     │
│  │  - iPXE Scripts                 │     │
│  │  - Node Configurations          │     │
│  └────────────────────────────────┘     │
│                                          │
│  ZFS Datasets:                           │
│  - tank/apps/pxe-bootstrap/data          │
│  - tank/apps/pxe-bootstrap/assets        │
│  - tank/apps/pxe-bootstrap/configs       │
└──────────────────────────────────────────┘
```

## Prerequisites

1. **TrueNAS SCALE 25.04+** (Fangtooth or later) with Incus support
2. **Ansible** installed locally
3. **1Password CLI** configured for secrets management
4. **DHCP server** configured with:
   ```
   next-server: <truenas-ip>
   filename: ipxe.efi
   ```

## Quick Start

1. **Set environment variables:**

   ```bash
   export TRUENAS_IP="10.0.5.10"
   export TRUENAS_API_KEY="your-api-key"  # Or store in 1Password
   ```

2. **Deploy the infrastructure:**

   ```bash
   task pxe:deploy
   ```

3. **Configure your nodes:**
   - Update MAC addresses in `inventory/hosts.yml`
   - Run: `task pxe:configure-nodes`

## Directory Structure

```
pxe-bootstrap/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts.yml           # Node inventory with MAC addresses
│   └── group_vars/         # Variable definitions
├── playbooks/
│   ├── deploy-matchbox.yml # Main deployment playbook
│   ├── configure-nodes.yml # Update node configurations
│   ├── rebuild-node.yml    # Rebuild specific node
│   └── provision-proxmox.yml # Post-install Proxmox config
├── roles/
│   ├── truenas-setup/      # TrueNAS dataset configuration
│   ├── matchbox/           # Matchbox container deployment
│   ├── talos-config/       # Talos node configurations
│   └── proxmox-config/     # Proxmox configurations
└── templates/              # Configuration templates
```

## Available Commands

```bash
# Deploy PXE infrastructure
task pxe:deploy

# Update node configurations
task pxe:configure-nodes

# Rebuild a specific node
task pxe:rebuild-node NODE=home01

# Configure Proxmox after PXE install
task pxe:provision-proxmox

# Check infrastructure status
task pxe:status

# View container logs
task pxe:logs

# Create backup snapshot
task pxe:backup

# Restore from snapshot
task pxe:restore SNAPSHOT=tank/apps/pxe-bootstrap@auto-20240315-120000
```

## Configuration

### Adding a New Talos Node

1. Edit `inventory/hosts.yml`:

   ```yaml
   talos_nodes:
     hosts:
       home06:
         mac_address: "aa:bb:cc:dd:ee:06"
         ip_address: "10.0.5.106"
         schematic: "EQ12"
         role: worker
   ```

2. Update configurations:

   ```bash
   task pxe:configure-nodes
   ```

3. Boot the node - it will automatically install Talos

### Adding a New Proxmox Node

1. Edit `inventory/hosts.yml`:

   ```yaml
   proxmox_nodes:
     hosts:
       pve03:
         mac_address: "ff:ee:dd:cc:bb:03"
         ip_address: "10.0.5.53"
         install_disk: "/dev/nvme0n1"
   ```

2. Update configurations:

   ```bash
   task pxe:configure-nodes
   ```

3. Boot the node - it will automatically install Proxmox

## Secrets Management

Secrets are managed via 1Password. Required items:

- `truenas-api`: TrueNAS API key
- `talos`: Machine tokens and certificates
- `proxmox-root`: Root password for Proxmox nodes

## Troubleshooting

### Check Matchbox Status

```bash
task pxe:status
```

### View Logs

```bash
task pxe:logs
```

### Test PXE Configuration

```bash
task pxe:test-boot MAC=7c:83:34:aa:bb:01
```

### Manual Container Access

```bash
ssh root@<truenas-ip>
incus exec matchbox -- /bin/bash
```

## Important Notes

- Incus Instances are marked "experimental" in TrueNAS 25.04
- Will be enterprise-ready in TrueNAS "Goldeye" (October 2025)
- The container runs unprivileged with port proxying
- All configurations are stored on ZFS with automatic snapshots

## Boot Process

1. **Node powers on** → BIOS/UEFI PXE boot
2. **DHCP request** → Gateway provides next-server
3. **TFTP request** → Downloads iPXE from TrueNAS
4. **iPXE chain** → Fetches configuration via HTTP
5. **Matchbox lookup** → MAC address determines boot profile
6. **OS installation** → Talos/Proxmox auto-installs
7. **Post-install** → Node configured and joins cluster
