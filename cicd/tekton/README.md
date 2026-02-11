# Tekton Pipeline for On-Premise Ubuntu Server

This directory contains Tekton pipeline manifests for deploying containerized applications on on-premise Ubuntu servers. The pipeline performs git clone, container image building with Buildah, and Helm-based deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Pipeline Components](#pipeline-components)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

## Overview

This Tekton pipeline provides a complete CI/CD workflow for containerized applications:

1. **Git Clone**: Fetches source code from a Git repository
2. **Buildah Build**: Builds container images using Buildah (no Docker daemon required)
3. **Helm Deploy**: Deploys the application to Kubernetes using Helm

### Key Features

- ✅ No application build step required (containers built directly with Buildah)
- ✅ Works on single-node on-premise Ubuntu servers
- ✅ Uses persistent workspace for shared data
- ✅ Supports both PVC and emptyDir workspaces
- ✅ Configurable parameters for flexibility
- ✅ Production-ready with proper error handling

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Tekton Pipeline                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ├─► Task 1: git-clone
                              │   └─► Clone source from Git repo
                              │
                              ├─► Task 2: buildah
                              │   ├─► Build container image
                              │   └─► Push to registry
                              │
                              └─► Task 3: helm-deploy
                                  └─► Deploy to Kubernetes
                                  
┌─────────────────────────────────────────────────────────────────┐
│                    Shared Workspace (PVC)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │  Source  │  │  Build   │  │  Charts  │                       │
│  │   Code   │  │ Context  │  │   Data   │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### 1. Kubernetes Cluster

A working Kubernetes cluster (can be single-node):

```bash
# For single-node Ubuntu server, you can use:
# - k3s (recommended): https://k3s.io/
# - microk8s: https://microk8s.io/
# - kind: https://kind.sigs.k8s.io/

# Example: Installing k3s
curl -sfL https://get.k3s.io | sh -

# Verify installation
kubectl get nodes
```

### 2. Tekton Pipelines

Install Tekton Pipelines on your cluster:

```bash
# Install Tekton Pipelines (v0.50.0 or later)
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Verify installation
kubectl get pods --namespace tekton-pipelines

# Wait for all pods to be running
kubectl wait --for=condition=Ready pods --all --namespace tekton-pipelines --timeout=300s
```

### 3. Storage Provisioner (for PVC)

For PVC-based workspaces, ensure you have a storage provisioner:

```bash
# Option 1: local-path provisioner (recommended for single-node)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Set as default storage class
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Verify
kubectl get storageclass
```

### 4. Container Registry Access

Ensure you have access to a container registry:

- **Local registry**: `docker run -d -p 5000:5000 --restart=always --name registry registry:2`
- **Docker Hub**: Credentials required
- **Quay.io**: Credentials required
- **GitHub Container Registry (ghcr.io)**: Personal access token required

### 5. Helm (for deployment target)

Helm must be available in the cluster or ensure the Helm task image has access to your cluster's API.

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/vriesjo/obseye.git
cd obseye/cicd/tekton
```

### 2. Install Pipeline Components

```bash
# Create namespace (if not using default)
kubectl create namespace default

# Install persistent volume claim
kubectl apply -f persistent-volume-claim.yaml

# Install tasks
kubectl apply -f tasks/git-clone.yaml
kubectl apply -f tasks/buildah.yaml
kubectl apply -f tasks/helm-deploy.yaml

# Install pipeline
kubectl apply -f pipeline.yaml
```

### 3. Verify Installation

```bash
# Check tasks
kubectl get tasks

# Expected output:
# NAME          AGE
# git-clone     10s
# buildah       10s
# helm-deploy   10s

# Check pipeline
kubectl get pipeline

# Expected output:
# NAME                     AGE
# obseye-deploy-pipeline   10s
```

### 4. Run the Pipeline

Edit `pipelinerun-example.yaml` with your configuration:

```yaml
params:
  - name: git-url
    value: "https://github.com/your-org/your-repo.git"
  - name: image-name
    value: "your-registry/your-image"
  - name: image-tag
    value: "v1.0.0"
  - name: helm-chart
    value: "./source/charts/your-chart"
```

Then run:

```bash
kubectl create -f pipelinerun-example.yaml
```

### 5. Monitor Pipeline Execution

```bash
# Watch pipeline run
kubectl get pipelinerun -w

# Get detailed status
kubectl describe pipelinerun obseye-deploy-run-example

# View logs
kubectl logs -f $(kubectl get pods --selector=tekton.dev/pipelineRun=obseye-deploy-run-example --output=name | head -1)

# Or use tkn CLI (if installed)
tkn pipelinerun logs obseye-deploy-run-example -f
```

## Pipeline Components

### Tasks

#### 1. git-clone

Clones a Git repository into the workspace.

**Parameters:**
- `url` (string): Git repository URL
- `revision` (string, default: "main"): Branch, tag, or commit SHA
- `subdirectory` (string, default: "source"): Target directory in workspace
- `depth` (string, default: "1"): Clone depth for shallow clone
- `sslVerify` (string, default: "true"): Verify SSL certificates

**Results:**
- `commit`: The exact commit SHA that was cloned
- `url`: The repository URL
- `committer-date`: Epoch timestamp of the commit

#### 2. buildah

Builds and pushes container images using Buildah.

**Parameters:**
- `IMAGE` (string): Full image reference (registry/name:tag)
- `DOCKERFILE` (string, default: "./Dockerfile"): Path to Dockerfile
- `CONTEXT` (string, default: "."): Build context path
- `TLSVERIFY` (string, default: "true"): Verify registry TLS
- `FORMAT` (string, default: "oci"): Image format (oci or docker)
- `BUILD_EXTRA_ARGS` (string): Additional build arguments
- `SKIP_PUSH` (string, default: "false"): Skip image push (for testing)

**Results:**
- `IMAGE_DIGEST`: SHA256 digest of the built image
- `IMAGE_URL`: Complete image URL

**Security Note:** This task requires privileged mode to run Buildah.

#### 3. helm-deploy

Deploys applications using Helm.

**Parameters:**
- `CHART` (string): Chart path or repository reference
- `RELEASE_NAME` (string): Name for the Helm release
- `RELEASE_NAMESPACE` (string, default: "default"): Target namespace
- `VALUES_FILE` (string): Path to custom values file
- `SET_VALUES` (string): Comma-separated key=value pairs
- `OVERWRITE_VALUES` (string): Values to override
- `CREATE_NAMESPACE` (string, default: "true"): Create namespace if missing
- `ATOMIC` (string, default: "true"): Rollback on failure
- `WAIT` (string, default: "true"): Wait for resources to be ready
- `TIMEOUT` (string, default: "5m0s"): Timeout for operations

**Results:**
- `RELEASE_NAME`: Name of the deployed release
- `RELEASE_NAMESPACE`: Namespace where deployed

### Pipeline

The main pipeline (`obseye-deploy-pipeline`) orchestrates all tasks with configurable parameters.

**Key Parameters:**
- Git: `git-url`, `git-revision`, `git-subdirectory`
- Build: `image-name`, `image-tag`, `dockerfile`, `build-context`, `skip-push`
- Deploy: `helm-chart`, `helm-release-name`, `helm-release-namespace`, `helm-values-file`, `helm-set-values`

### Workspaces

The pipeline uses a shared workspace (`shared-data`) for data persistence across tasks.

**Three workspace options:**

1. **PersistentVolumeClaim (Recommended)**
   ```yaml
   workspaces:
     - name: shared-data
       persistentVolumeClaim:
         claimName: tekton-workspace-pvc
   ```

2. **EmptyDir (Testing/Single-node)**
   ```yaml
   workspaces:
     - name: shared-data
       emptyDir: {}
   ```

3. **VolumeClaimTemplate (Dynamic)**
   ```yaml
   workspaces:
     - name: shared-data
       volumeClaimTemplate:
         spec:
           accessModes: [ReadWriteOnce]
           resources:
             requests:
               storage: 10Gi
   ```

## Configuration

### Container Registry Authentication

For private registries, create a Kubernetes secret:

```bash
# Docker Hub
kubectl create secret docker-registry docker-credentials \
  --docker-server=docker.io \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com

# Quay.io
kubectl create secret docker-registry quay-credentials \
  --docker-server=quay.io \
  --docker-username=your-username \
  --docker-password=your-password

# GitHub Container Registry
kubectl create secret docker-registry ghcr-credentials \
  --docker-server=ghcr.io \
  --docker-username=your-github-username \
  --docker-password=your-github-token
```

Then reference in PipelineRun:

```yaml
spec:
  podTemplate:
    imagePullSecrets:
      - name: docker-credentials
```

### Kubeconfig for Helm (if needed)

If Helm needs to access a different cluster:

```bash
kubectl create secret generic kubeconfig \
  --from-file=config=$HOME/.kube/config
```

Mount in task:

```yaml
workspaces:
  - name: kubeconfig
    secret:
      secretName: kubeconfig
```

### Storage Class Configuration

Edit `persistent-volume-claim.yaml` to specify storage class:

```yaml
spec:
  storageClassName: local-path  # or standard, nfs-client, etc.
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## Usage Examples

### Example 1: Simple Deployment

```bash
# Create a minimal PipelineRun
cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: obseye-deploy-
spec:
  pipelineRef:
    name: obseye-deploy-pipeline
  workspaces:
    - name: shared-data
      emptyDir: {}
  params:
    - name: git-url
      value: "https://github.com/vriesjo/obseye.git"
    - name: image-name
      value: "localhost:5000/obseye"
    - name: image-tag
      value: "latest"
    - name: helm-chart
      value: "./source/charts/obseye"
EOF
```

### Example 2: Production Deployment with PVC

```bash
# First, create the PVC
kubectl apply -f persistent-volume-claim.yaml

# Then run the pipeline
cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: obseye-prod-
spec:
  pipelineRef:
    name: obseye-deploy-pipeline
  workspaces:
    - name: shared-data
      persistentVolumeClaim:
        claimName: tekton-workspace-pvc
  params:
    - name: git-url
      value: "https://github.com/vriesjo/obseye.git"
    - name: git-revision
      value: "v1.2.3"
    - name: image-name
      value: "quay.io/my-org/obseye"
    - name: image-tag
      value: "1.2.3"
    - name: helm-chart
      value: "./source/charts/obseye"
    - name: helm-release-namespace
      value: "production"
    - name: helm-set-values
      value: "replicaCount=5,resources.requests.memory=2Gi"
EOF
```

### Example 3: Multi-Environment Deployment

```bash
# Development environment
kubectl create -f pipelinerun-example.yaml \
  --dry-run=client -o yaml | \
  sed 's/image-tag: "1.0.0"/image-tag: "dev-latest"/' | \
  sed 's/helm-release-namespace: "default"/helm-release-namespace: "development"/' | \
  kubectl apply -f -

# Staging environment
kubectl create -f pipelinerun-example.yaml \
  --dry-run=client -o yaml | \
  sed 's/image-tag: "1.0.0"/image-tag: "v1.2.3"/' | \
  sed 's/helm-release-namespace: "default"/helm-release-namespace: "staging"/' | \
  kubectl apply -f -
```

### Example 4: Build-Only (Skip Push)

For testing image builds locally:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: obseye-build-test-
spec:
  pipelineRef:
    name: obseye-deploy-pipeline
  workspaces:
    - name: shared-data
      emptyDir: {}
  params:
    - name: git-url
      value: "https://github.com/vriesjo/obseye.git"
    - name: image-name
      value: "test-image"
    - name: skip-push
      value: "true"
    - name: helm-chart
      value: "./source/charts/obseye"
EOF
```

## Troubleshooting

### Common Issues

#### 1. PVC Not Binding

**Problem:** PVC stays in `Pending` state

**Solution:**
```bash
# Check PVC status
kubectl get pvc tekton-workspace-pvc

# Check storage classes
kubectl get storageclass

# If no default storage class, create one or specify storageClassName in PVC
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### 2. Buildah Permission Denied

**Problem:** `ERRO error creating build container: creating new container: mkdir /var/lib/containers/storage`

**Solution:** Ensure the buildah task runs with `privileged: true` (already configured)

#### 3. Image Push Fails

**Problem:** `unauthorized: authentication required`

**Solution:**
```bash
# Create registry credentials secret
kubectl create secret docker-registry registry-credentials \
  --docker-server=your-registry.com \
  --docker-username=username \
  --docker-password=password

# Add to PipelineRun
spec:
  podTemplate:
    imagePullSecrets:
      - name: registry-credentials
```

#### 4. Helm Deploy Fails

**Problem:** `Error: INSTALLATION FAILED: Kubernetes cluster unreachable`

**Solution:**
```bash
# Verify service account has proper RBAC permissions
kubectl create clusterrolebinding tekton-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:default

# Or create specific role for namespace
kubectl create rolebinding tekton-deploy \
  --clusterrole=edit \
  --serviceaccount=default:default \
  --namespace=your-namespace
```

#### 5. Git Clone Fails with SSL Error

**Problem:** `fatal: unable to access 'https://...': SSL certificate problem`

**Solution:** Set `sslVerify` parameter to "false" in PipelineRun (not recommended for production)

```yaml
params:
  - name: git-url
    value: "https://..."
```

And modify git-clone task to set `sslVerify: "false"` parameter.

### Debugging Commands

```bash
# List all PipelineRuns
kubectl get pipelineruns

# Get PipelineRun details
kubectl describe pipelinerun <pipelinerun-name>

# Get logs from specific task
kubectl logs <pod-name> -c step-<step-name>

# Get all logs from a PipelineRun
tkn pipelinerun logs <pipelinerun-name> -f

# Delete failed PipelineRuns
kubectl delete pipelinerun --field-selector=status.conditions[0].status=False

# Clean up completed PipelineRuns (older than 1 day)
kubectl get pipelinerun --sort-by=.metadata.creationTimestamp | \
  awk 'NR>1 {print $1}' | \
  head -n -5 | \
  xargs -r kubectl delete pipelinerun
```

### Logs and Monitoring

```bash
# Watch pipeline execution in real-time
kubectl get pipelinerun -w

# Get events related to pipeline
kubectl get events --sort-by=.metadata.creationTimestamp

# Install Tekton Dashboard for UI
kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml

# Access dashboard (after port-forward)
kubectl port-forward -n tekton-pipelines service/tekton-dashboard 9097:9097
# Open browser to http://localhost:9097
```

## Additional Resources

- **Tekton Documentation**: https://tekton.dev/docs/
- **Tekton Catalog**: https://hub.tekton.dev/
- **Buildah Documentation**: https://buildah.io/
- **Helm Documentation**: https://helm.sh/docs/
- **Kubernetes Documentation**: https://kubernetes.io/docs/

## Contributing

To improve this pipeline:

1. Test changes in a development environment
2. Update documentation as needed
3. Follow Tekton best practices
4. Ensure backward compatibility

## License

This pipeline configuration is provided as-is for use with open-source tools.
