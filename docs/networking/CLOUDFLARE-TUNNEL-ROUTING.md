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

To make a service accessible via the external gateway through the tunnel:

1. Set the service's HTTPRoute to use the external gateway:

   ```yaml
   route:
     app:
       parentRefs:
         - name: external
           namespace: kube-system
           sectionName: https
   ```

2. The cloudflared init container will automatically detect this and route traffic accordingly

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

## Migration Notes

Previously, the cloudflared configuration was static and required manual updates when services needed external routing. With this dynamic system:

- Services declare their routing needs in their own configuration
- No changes needed to cloudflared when adding/removing external services
- Routing decisions are consistent with the Gateway API model
