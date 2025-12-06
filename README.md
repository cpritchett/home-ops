<div align="center">

### My homelab k8s cluster <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="16" height="16">

_... automated via [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), and [GitHub Actions](https://github.com/features/actions)_ <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=%20)](https://fluxcd.io)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/cpritchett/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/cpritchett/home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Home-Internet](https://img.shields.io/endpoint?url=https%3A%2F%2Fstatus.hypyr.space%2Fapi%2Fv1%2Fendpoints%2F_internet-connectivity%2Fhealth%2Fbadge.shields&style=for-the-badge&logo=ubiquiti&logoColor=white&label=Home%20Internet)](https://status.hypyr.space)&nbsp;&nbsp;
[![Status-Page](https://img.shields.io/endpoint?url=https%3A%2F%2Fstatus.hypyr.space%2Fapi%2Fv1%2Fendpoints%2F_gatus%2Fhealth%2Fbadge.shields&style=for-the-badge&logo=statuspage&logoColor=white&label=Status%20Page)](https://status.hypyr.space)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Alerts](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.hypyr.space%2Fcluster_alert_count&style=flat-square&label=Alerts)](https://github.com/kashalls/kromgo)

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.gif" alt="💡" width="20" height="20"> Overview

This is a repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Kubernetes](https://github.com/kubernetes/kubernetes), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), and [GitHub Actions](https://github.com/features/actions).

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f331/512.gif" alt="🌱" width="20" height="20"> Kubernetes

This semi hyper-converged cluster operates on [Talos Linux](https://github.com/siderolabs/talos), an immutable and ephemeral Linux distribution tailored for [Kubernetes](https://github.com/kubernetes/kubernetes), and is deployed on bare-metal [MS-A2](https://store.minisforum.com/products/minisforum-ms-a2) workstations. [Rook](https://github.com/rook/rook) supplies my workloads with persistent block, object, and file storage, while a separate server handles media file storage. The cluster is designed to enable a full teardown without any data loss.

There is a template at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) if you want to follow along with some of the practices I use here.

### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [cert-manager](https://github.com/cert-manager/cert-manager): Creates SSL certificates for services in my cluster.
- [cilium](https://github.com/cilium/cilium): eBPF-based networking for my workloads.
- [cloudflared](https://github.com/cloudflare/cloudflared): Enables Cloudflare secure access to my routes.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically syncs ingress DNS records to a DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [multus](https://github.com/k8snetworkplumbingwg/multus-cni): Multi-homed pod networking.
- [rook](https://github.com/rook/rook): Distributed block storage for persistent storage.
- [spegel](https://github.com/spegel-org/spegel): Stateless cluster local OCI registry mirror.
- [volsync](https://github.com/backube/volsync): Backup and recovery of persistent volume claims.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes) folder (see Directories below) and makes the changes to my clusters based on the state of my Git repository.

The way Flux works for me here is it will recursively search the [kubernetes/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations (`ks.yaml`). Under the control of those Flux kustomizations there will be a `HelmRelease` or other resources related to the application which will be applied.

[Renovate](https://github.com/renovatebot/renovate) monitors my **entire** repository for dependency updates, automatically creating a PR when updates are found. When some PRs are merged Flux applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 apps          # Apps deployed into my cluster grouped by namespace (see below)
├─📁 components    # Re-usable kustomize components
└─📁 flux          # Flux system configuration
```

### Cluster layout

This shows the two fundamental infrastructure workflows that enable secure, stateful applications in GitOps. These dependency chains solve the hardest problems newcomers face when building production-ready clusters: **secrets management** and **persistent storage**.

#### GitOps Security Pipeline 🔒

_Solves the "chicken and egg" problem of bootstrapping secrets in GitOps_

```mermaid
graph LR
    A[1Password Vault]:::vault -->|Credentials| B[1Password Connect]:::connect
    B -->|Creates| C[ClusterSecretStore]:::store
    C -->|Enables| D[ExternalSecret]:::external
    D -->|Syncs to| E[Kubernetes Secret]:::secret
    E -->|Consumed by| F[Application Pods]:::app

    classDef vault fill:#0066CC,stroke:#004499,stroke-width:2px,color:#fff;
    classDef connect fill:#FF6B35,stroke:#CC5529,stroke-width:2px,color:#fff;
    classDef store fill:#9C27B0,stroke:#7B1FA2,stroke-width:2px,color:#fff;
    classDef external fill:#FF9800,stroke:#F57C00,stroke-width:2px,color:#fff;
    classDef secret fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff;
    classDef app fill:#2196F3,stroke:#0D47A1,stroke-width:2px,color:#fff;
```

#### Storage + Backup Foundation 💾

_Provides persistent storage with automated backup/restore capabilities_

```mermaid
graph TD
    A[Snapshot Controller]:::controller -->|Manages| B[VolumeSnapshots]:::snapshot
    A -->|Enables| C[Rook Ceph Operator]:::operator
    C -->|Creates| D[Ceph Cluster]:::cluster
    D -->|Provides| E[StorageClasses]:::storage
    E -->|Creates| F[PVCs]:::pvc
    F -->|Backed up by| G[VolSync]:::volsync
    G -->|Uses| B
    F -->|Consumed by| H[Stateful Apps]:::app

    classDef controller fill:#6A1B9A,stroke:#4A148C,stroke-width:2px,color:#fff;
    classDef snapshot fill:#8E24AA,stroke:#6A1B9A,stroke-width:2px,color:#fff;
    classDef operator fill:#00ACC1,stroke:#00838F,stroke-width:2px,color:#fff;
    classDef cluster fill:#26A69A,stroke:#00695C,stroke-width:2px,color:#fff;
    classDef storage fill:#66BB6A,stroke:#2E7D32,stroke-width:2px,color:#fff;
    classDef pvc fill:#42A5F5,stroke:#0D47A1,stroke-width:2px,color:#fff;
    classDef volsync fill:#FFA726,stroke:#E65100,stroke-width:2px,color:#fff;
    classDef app fill:#EF5350,stroke:#C62828,stroke-width:2px,color:#fff;
```

**Why These Workflows Matter:**

🔐 **Security Pipeline**: Traditional "secrets in git" approaches don't work for production. This 1Password Connect workflow solves the bootstrap problem by providing a secure, auditable way to inject secrets into your cluster without storing them in Git. Each ExternalSecret automatically syncs from 1Password, enabling secure GitOps practices.

**Why External Secret Stores?** While SOPS (Secrets OPerationS) is popular for encrypting secrets in GitOps homelabs, I just don't like it. I don't like dealing with the vscode plugins, and I don't like managing yet another tool. What I do like is using the secret manager where my passwords already live.

**Secret Store Options**: This cluster uses **1Password Connect** (self-hosted), but there are many alternatives. Popular choices include HashiCorp Vault (powerful but complex), Bitwarden (familiar and self-hostable), Infisical (modern developer experience), and Doppler (simple cloud integration). 1Password also offers Service Accounts for easier cloud-based setup.

Check the [Home Operations Discord](https://discord.gg/home-operations) for community experiences with different providers. Your choice depends on your security requirements, operational preferences, and existing infrastructure.

💾 **Storage Foundation**: Stateful applications need reliable storage with backup/restore capabilities. This workflow shows how Rook Ceph provides distributed storage while VolSync handles automated backups using VolumeSnapshots. The Snapshot Controller enables point-in-time recovery for all your critical data.

### Networking

<details>
  <summary>Click to see a high-level network diagram</summary>

</details>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f30e/512.gif" alt="🌎" width="20" height="20"> DNS

In my cluster there are two instances of [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) running. One for syncing private DNS records to my `UDM Pro Max` using [ExternalDNS webhook provider for UniFi](https://github.com/kashalls/external-dns-unifi-webhook), while another instance syncs public DNS to `Cloudflare`. This setup is managed by creating routes with two specific gatways: `internal` for private DNS and `external` for public DNS. The `external-dns` instances then syncs the DNS records to their respective platforms accordingly.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2699_fe0f/512.gif" alt="⚙" width="20" height="20"> Hardware

<details>
  <summary>Click to see my rack</summary>

  <img src="https://github.com/user-attachments/assets/43bd0ca8-a1a8-49d5-9b9a-04fbdcecdd3f" align="center" alt="rack"/>
</details>

| Device                     | Count | OS Disk Size  | Data Disk Size    | Ram   | Operating System | Purpose                 |
| -------------------------- | ----- | ------------- | ----------------- | ----- | ---------------- | ----------------------- |
| Beelink EQ12               | 2     | 512GB (SSD)   | 512GB (NVME)      | 32GB  | Talos            | Kubernetes              |
| Intel NUC7                 | 1     | 512GB (SSD)   | 512GB (NVME)      | 32GB  | Talos            | Kubernetes              |
| 45Drives HL15              | 1     | 2x512GB (SSD) | 8x14TB HDD        | 128GB | TrueNAS Scale    | NFS                     |
| PiKVM (RasPi 4)            | 1     | -             | -                 | 4GB   | PiKVM            | KVM                     |
| TESmart 8 Port KVM Switch  | 1     | -             | -                 | -     | -                | Network KVM (for PiKVM) |
| UniFi Gateway Max          | 1     | -             | 512 (NVME)        | -     | UniFi OS         | Router & NVR            |
| UniFi USW Enterprise 8 POE | 1     | -             | -                 | -     | UniFi OS         | 2.5Gb Core Switch       |
| UniFi USW Pro 8            | 1     | -             | -                 | -     | UniFi OS         | Garage PoE Switch       |
| Lenovo Thinkstation P520   | 1     | -             | Many Mixed NVME's | 128GB | UnRAID           | Secondary/Flash NAS     |

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f527/512.gif" alt="🔧" width="20" height="20"> Troubleshooting

### Common Issues

- **Renovate Permission Issues**: If you see "Cannot access vulnerability alerts" or "Package lookup failures", see [`docs/RENOVATE-TROUBLESHOOTING.md`](./docs/RENOVATE-TROUBLESHOOTING.md)
- **Renovate Configuration**: For details on how Renovate is configured and best practices, see [`docs/RENOVATE-CONFIG-GUIDE.md`](./docs/RENOVATE-CONFIG-GUIDE.md)
- **Cluster Issues**: For node, storage, or networking problems, see [`docs/CLUSTER-TROUBLESHOOTING.md`](./docs/CLUSTER-TROUBLESHOOTING.md)
- **Setup Issues**: For initial setup problems, see [`docs/SETUP-GUIDE.md`](./docs/SETUP-GUIDE.md)

### Quick Fixes

```bash
# Fix secret sync issues
task k8s:sync-secrets

# Fix Renovate permissions
./scripts/fix-renovate-permissions.sh

# Browse storage issues
task k8s:browse-pvc CLAIM=<pvc-name>
```

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f31f/512.gif" alt="🌟" width="20" height="20"> Stargazers

<div align="center">

<a href="https://star-history.com/#cpritchett/home-ops&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=cpritchett/home-ops&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=cpritchett/home-ops&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=cpritchett/home-ops&type=Date" />
  </picture>
</a>

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f64f/512.gif" alt="🙏" width="20" height="20"> Gratitude and Thanks

Many thanks to [@onedrop](https://github.com/onedr0p), [@buroa](https://github.com/buroa) and all the fantastic people who donate their time to the [Home Operations](https://discord.gg/home-operations) Discord community. Be sure to check out [kubesearch.dev](https://kubesearch.dev) for ideas on how to deploy applications or get ideas on what you may deploy.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6a7/512.gif" alt="🚧" width="20" height="20"> Changelog

See the latest [release](https://github.com/cpritchett/home-ops/releases/latest) notes.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2696_fe0f/512.gif" alt="⚖" width="20" height="20"> License

See [LICENSE](./LICENSE).
