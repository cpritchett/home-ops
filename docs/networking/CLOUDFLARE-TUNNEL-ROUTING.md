# Cloudflare Tunnel Dynamic Routing

## Overview

The Cloudflare tunnel (`cloudflared`) automatically configures routing based on HTTPRoute resources in the cluster. Services are routed to either the internal or external gateway based on their `parentRefs` configuration.

## How It Works

1. **Default Behavior**: All traffic is routed to the internal gateway (`cilium-gateway-internal`)
2. **External Services**: Services with `parentRefs: external` are automatically routed to the external gateway
3. **Dynamic Discovery**: An init container queries all HTTPRoutes at startup and generates the tunnel configuration

## Architecture

```
Internet -> Cloudflare Tunnel -> Dynamic Routing Decision
                                  ├─> External Gateway (for services with parentRefs: external)
                                  └─> Internal Gateway (default for everything else)
```

## Service Configuration

### Default Behavior

Services with `parentRefs: external` are automatically routed through the external gateway.

```yaml
route:
  app:
    parentRefs:
      - name: external
        namespace: kube-system
        sectionName: https
```

### Advanced Scenarios

#### Tunnel-Only Access (No Public DNS)

For services that need tunnel access but should not have public DNS records created by external-dns:

**Use Case**: Badge endpoints like kromgo that need to be accessible via Cloudflare tunnel for shields.io but shouldn't bypass tunnel routing with direct public DNS.

```yaml
# Method 1: In HelmRelease route configuration
route:
  app:
    annotations:
      # Prevent external-dns from creating public DNS records
      external-dns.alpha.kubernetes.io/exclude: "true"
    parentRefs:
      - name: external
        namespace: kube-system

# Method 2: Separate HTTPRoute resource (recommended for complex routing)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service
  namespace: my-namespace
  annotations:
    # Force tunnel-only access by excluding from external-dns
    external-dns.alpha.kubernetes.io/exclude: "true"
spec:
  hostnames:
    - my-service.hypyr.space
  parentRefs:
    - name: external
      namespace: kube-system
      sectionName: https
  rules:
    - backendRefs:
        - name: my-service
          port: 80
```

**Why This Works**: The service routes through the external gateway (accessible via tunnel) but external-dns skips creating public DNS records that would bypass the tunnel.

#### External Gateway but No Tunnel

For services on external gateway that should NOT be accessible via tunnel:

```yaml
route:
  app:
    annotations:
      # Skip tunnel routing entirely
      tunnel.cloudflare.io/exclude: "true"
    parentRefs:
      - name: external
        namespace: kube-system
```

#### Force External Routing

For internal services that temporarily need external tunnel routing:

```yaml
route:
  app:
    annotations:
      # Force tunnel to route to external gateway
      tunnel.cloudflare.io/route: "external"
    parentRefs:
      - name: internal # Still on internal gateway
        namespace: kube-system
```

## Implementation Details

### Components

- **Init Container**: Runs before cloudflared starts, queries HTTPRoutes, generates config
- **RBAC**: ServiceAccount with permissions to read HTTPRoutes across all namespaces
- **Generated Config**: Stored in an emptyDir volume, regenerated on each pod restart

### Benefits

- **No Manual Configuration**: Services control their own routing via `parentRefs`
- **Consistent with Gateway API**: Uses the same configuration pattern as the rest of the cluster
- **Self-Documenting**: Service routing is declared in the service's own configuration
- **No Hardcoding**: Tunnel configuration is generated dynamically

## Troubleshooting

### Check Generated Config

```bash
kubectl exec -n networking deployment/cloudflared -- cat /etc/cloudflared/config.yaml
```

### View Init Container Logs

```bash
kubectl logs -n networking deployment/cloudflared -c generate-config
```

### List External Services

```bash
kubectl get httproute -A -o json | jq -r '.items[] | select(.spec.parentRefs[]?.name == "external") | "\(.metadata.namespace)/\(.metadata.name): \(.spec.hostnames[]?)"'
```

### Check Tunnel-Only Services

List services using tunnel-only routing (external gateway + external-dns exclude):

```bash
kubectl get httproute -A -o json | jq -r '.items[] | select(.spec.parentRefs[]?.name == "external" and .metadata.annotations["external-dns.alpha.kubernetes.io/exclude"] == "true") | "\(.metadata.namespace)/\(.metadata.name): \(.spec.hostnames[]?) (tunnel-only)"'
```

## Migration Notes

Previously, the cloudflared configuration was static and required manual updates when services needed external routing. With this dynamic system:

- Services declare their routing needs in their own configuration
- No changes needed to cloudflared when adding/removing external services
- Routing decisions are consistent with the Gateway API model
