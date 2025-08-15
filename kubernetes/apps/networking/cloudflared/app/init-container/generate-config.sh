#!/bin/sh
# Init container script to generate cloudflared config from HTTPRoutes
set -e

CONFIG_FILE="/etc/cloudflared/config.yaml"
EXTERNAL_GATEWAY="https://cilium-gateway-external.kube-system.svc.cluster.local"
INTERNAL_GATEWAY="https://cilium-gateway-internal.kube-system.svc.cluster.local"

echo "Generating cloudflared config from HTTPRoutes..."

# Start config file
cat >"$CONFIG_FILE" <<EOF
---
# Auto-generated from HTTPRoutes - DO NOT EDIT
originRequest:
  originServerName: internal.hypyr.space

ingress:
EOF

# Query all HTTPRoutes that reference the external gateway
echo "  # External gateway services (from HTTPRoutes)" >>"$CONFIG_FILE"

# Get all HTTPRoutes across all namespaces that reference external gateway
# Skip routes with tunnel.cloudflare.io/exclude: "true" annotation
kubectl get httproute -A -o json | jq -r '
  .items[] | 
  select(.spec.parentRefs[]?.name == "external") |
  select(.metadata.annotations["tunnel.cloudflare.io/exclude"] != "true") |
  .spec.hostnames[]? // empty
' | while read -r hostname; do
    if [ -n "$hostname" ]; then
        echo "  - hostname: $hostname" >>"$CONFIG_FILE"
        echo "    service: $EXTERNAL_GATEWAY" >>"$CONFIG_FILE"
        echo "Found external route: $hostname"
    fi
done

# Add routes that explicitly want tunnel routing even if on internal gateway
# Look for tunnel.cloudflare.io/route: "external" annotation
kubectl get httproute -A -o json | jq -r '
  .items[] |
  select(.metadata.annotations["tunnel.cloudflare.io/route"] == "external") |
  select(.spec.parentRefs[]?.name != "external") |
  .spec.hostnames[]? // empty
' | while read -r hostname; do
    if [ -n "$hostname" ]; then
        echo "  - hostname: $hostname" >>"$CONFIG_FILE"
        echo "    service: $EXTERNAL_GATEWAY" >>"$CONFIG_FILE"
        echo "Found annotated external route: $hostname"
    fi
done

# Add default routes
cat >>"$CONFIG_FILE" <<EOF
  # Default: ALL traffic goes to internal gateway
  - hostname: hypyr.space
    service: $INTERNAL_GATEWAY
  - hostname: "*.hypyr.space"
    service: $INTERNAL_GATEWAY
  - service: http_status:404
EOF

echo "Config generation complete!"
cat "$CONFIG_FILE"
