# YAML and Helm Templating Guide

This guide covers YAML syntax rules and Helm templating best practices to avoid common parsing errors and ensure proper template evaluation.

## YAML Quoting Rules

### When to Quote Values

YAML values should be quoted in these cases:

1. **Strings that could be interpreted as other types**:

   ```yaml
   # Good
   version: "1.0"
   port: "8080"
   enabled: "true"

   # Bad (might be parsed as number/boolean)
   version: 1.0
   port: 8080
   enabled: true
   ```

2. **Strings containing special characters**:

   ```yaml
   # Good
   url: "https://example.com:8080/path?query=value"
   message: "Hello, world!"

   # Bad (colon might break parsing)
   url: https://example.com:8080/path?query=value
   message: Hello, world!
   ```

3. **Strings starting with YAML indicators**:

   ```yaml
   # Good
   command: "- echo hello"
   data: "{ key: value }"

   # Bad (interpreted as array/object)
   command: - echo hello
   data: { key: value }
   ```

### When NOT to Quote

1. **Pure strings without special meaning**:

   ```yaml
   name: myapp
   namespace: default
   ```

2. **Numeric values when you want numbers**:

   ```yaml
   replicas: 3
   port: 8080
   ```

3. **Boolean values when you want booleans**:
   ```yaml
   enabled: true
   debug: false
   ```

## Helm Template Expression Quoting

### Critical Rule: Template Expressions as YAML Values MUST be Quoted

**Why**: Unquoted template expressions like `{{ .Release.Name }}` are parsed as YAML objects, not strings.

### Correct Patterns

1. **PVC References**:

   ```yaml
   # Good
   persistence:
     config:
       existingClaim: "{{ .Release.Name }}"
     cache:
       existingClaim: "{{ .Release.Name }}-cache"

   # Bad - causes "invalid map key" errors
   persistence:
     config:
       existingClaim: {{ .Release.Name }}
   ```

2. **Secret and ConfigMap Names**:

   ```yaml
   # Good
   envFrom:
     - secretRef:
         name: "{{ .Release.Name }}-secret"

   persistence:
     config-file:
       type: configMap
       name: "{{ .Release.Name }}-configmap"

   # Bad - causes YAML parsing errors
   envFrom:
     - secretRef:
         name: {{ .Release.Name }}-secret
   ```

3. **Hostname Lists**:

   ```yaml
   # Good
   route:
     app:
       hostnames:
         - "{{ .Release.Name }}.hypyr.space"
         - app.hypyr.space

   # Bad - causes "expected <block end>" errors
   route:
     app:
       hostnames:
         - {{ .Release.Name }}.hypyr.space
   ```

4. **Environment Variables**:

   ```yaml
   # Good
   env:
     APP_NAME: "{{ .Release.Name }}"
     APP_NAMESPACE: "{{ .Release.Namespace }}"
     APP_URL: "https://{{ .Release.Name }}.hypyr.space"

   # Bad - causes "invalid map key" errors
   env:
     APP_NAME: {{ .Release.Name }}
     APP_NAMESPACE: {{ .Release.Namespace }}
   ```

5. **Service Configuration**:

   ```yaml
   # Good
   service:
     app:
       forceRename: "{{ .Release.Name }}"

   # Bad
   service:
     app:
       forceRename: {{ .Release.Name }}
   ```

6. **Storage Class Parameters**:

   ```yaml
   # Good
   parameters:
     csi.storage.k8s.io/provisioner-secret-namespace: "{{ .Release.Namespace }}"

   # Bad
   parameters:
     csi.storage.k8s.io/provisioner-secret-namespace: {{ .Release.Namespace }}
   ```

### Exception: Template Expressions as Keys

Template expressions used as YAML keys should NOT be quoted:

```yaml
# This is rare and usually not recommended, but if needed:
{ { .Values.dynamicKey } }: value
```

## Common Error Patterns and Fixes

### Error: `yaml: invalid map key`

**Cause**: Unquoted template expression interpreted as object

```yaml
# Bad
existingClaim: {{ .Release.Name }}

# Fix
existingClaim: "{{ .Release.Name }}"
```

### Error: `expected <block end>, but found '<scalar>'`

**Cause**: Unquoted template in list item

```yaml
# Bad
hostnames:
  - {{ .Release.Name }}.hypyr.space

# Fix
hostnames:
  - "{{ .Release.Name }}.hypyr.space"
```

### Error: `did not find expected key`

**Cause**: Missing quotes on complex template concatenation

```yaml
# Bad
name: {{ .Release.Name }}-secret

# Fix
name: "{{ .Release.Name }}-secret"
```

## Template Expression Guidelines

1. **Always quote template expressions when used as YAML values**
2. **Use consistent naming patterns**:
   - Secrets: `"{{ .Release.Name }}-secret"`
   - ConfigMaps: `"{{ .Release.Name }}-configmap"`
   - Cache volumes: `"{{ .Release.Name }}-cache"`

3. **For complex expressions, always quote the entire result**:

   ```yaml
   # Good
   url: "https://{{ .Release.Name }}.{{ .Values.domain }}:{{ .Values.port }}/path"

   # Bad
   url: https://{{ .Release.Name }}.{{ .Values.domain }}:{{ .Values.port }}/path
   ```

## Testing YAML Validity

Before committing changes, test YAML syntax:

```bash
# Single document
python3 -c "import yaml; yaml.safe_load(open('file.yaml').read()); print('Valid')"

# Multiple documents (common in Kubernetes)
python3 -c "import yaml; list(yaml.safe_load_all(open('file.yaml').read())); print('Valid')"
```

## HelmRelease-Specific Patterns

In Flux HelmReleases, template expressions in the `values` section are processed by Helm, so they must follow proper YAML syntax while being valid Helm templates:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: myapp
spec:
  values:
    # All template expressions here MUST be quoted as YAML values
    persistence:
      data:
        existingClaim: "{{ .Release.Name }}"

    service:
      app:
        forceRename: "{{ .Release.Name }}"

    route:
      app:
        hostnames:
          - "{{ .Release.Name }}.hypyr.space"
```

Following these patterns will prevent common YAML parsing errors and ensure proper Helm template evaluation in your GitOps workflows.
