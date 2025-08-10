---
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-secret
  namespace: external-secrets
type: Opaque
stringData:
  # IMPORTANT: 1Password Connect requires base64-encoded credentials
  # The OP_CREDENTIALS_JSON field in 1Password is already base64 encoded
  # Using stringData will base64 encode it again (double encoding as required)
  # See: https://github.com/1Password/connect-helm-charts/issues/202
  1password-credentials.json: op://homelab/1password/OP_CREDENTIALS_JSON
  token: op://homelab/1password/OP_CONNECT_TOKEN
