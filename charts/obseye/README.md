# Obseye Helm Chart

This Helm chart deploys the obseye monitoring configuration container to Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `obseye`:

```bash
# From the repository root
helm install obseye ./charts/obseye

# Or with custom values
helm install obseye ./charts/obseye -f custom-values.yaml

# Or setting values via command line
helm install obseye ./charts/obseye \
  --set image.repository=myregistry/obseye \
  --set image.tag=1.0.0 \
  --set replicaCount=3
```

## Uninstalling the Chart

```bash
helm uninstall obseye
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `localhost:5000/obseye` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag | `latest` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `resources.limits.cpu` | CPU limit | `100m` |
| `resources.limits.memory` | Memory limit | `128Mi` |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `64Mi` |

## Example Custom Values

Create a `custom-values.yaml`:

```yaml
replicaCount: 3

image:
  repository: quay.io/myorg/obseye
  tag: "1.0.0"

service:
  type: LoadBalancer
  port: 8080

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

Then install:

```bash
helm install obseye ./charts/obseye -f custom-values.yaml
```
