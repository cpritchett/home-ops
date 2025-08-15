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
kubectl get httproute -A -o json | jq -r '
  .items[] | 
  select(.spec.parentRefs[]?.name == "external") |
  .spec.hostnames[]? // empty
' | while read -r hostname; do
    if [ -n "$hostname" ]; then
        echo "  - hostname: $hostname" >>"$CONFIG_FILE"
        echo "    service: $EXTERNAL_GATEWAY" >>"$CONFIG_FILE"
        echo "Found external route: $hostname"
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
