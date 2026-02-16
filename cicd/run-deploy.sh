#!/usr/bin/env sh
# Small helper to create tekton Task/Pipeline and run the PipelineRun using `kc` (your kubectl alias).
# Requirements:
# - tekton-pipelines is installed in the cluster
# - a Secret named `tekton-kubeconfig` exists with key `kubeconfig` containing a kubeconfig with permissions to apply manifests
# - 'kc' is available and points to the right cluster

set -eu
HERE_DIR="$(cd "$(dirname "$0")" && pwd)"
KC_CMD=${KC_CMD:-kc}
NAMESPACE=${NAMESPACE:-default}
REPO_URL=${REPO_URL:-$(git config --get remote.origin.url || echo "")}
REVISION=${REVISION:-main}
MANIFEST_PATH=${MANIFEST_PATH:-deployment.yaml}

echo "Applying Task and Pipeline definitions to namespace ${NAMESPACE}..."
${KC_CMD} apply -f "${HERE_DIR}/task-deploy-from-git.yaml" -n "${NAMESPACE}"
${KC_CMD} apply -f "${HERE_DIR}/pipeline-deploy.yaml" -n "${NAMESPACE}"

# Create a param-file for the PipelineRun with the values to override
cat > "${HERE_DIR}/pipelinerun-params.yaml" <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: pipeline-deploy-run-
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: pipeline-deploy
  params:
    - name: url
      value: "${REPO_URL}"
    - name: revision
      value: "${REVISION}"
    - name: manifestPath
      value: "${MANIFEST_PATH}"
  workspaces:
    - name: shared-workspace
      emptyDir: {}
EOF

echo "Starting PipelineRun (this will create a PipelineRun resource)..."
${KC_CMD} apply -f "${HERE_DIR}/pipelinerun-params.yaml" -n "${NAMESPACE}"

echo "You can watch the run with:"
echo "  ${KC_CMD} get pipelineruns -n ${NAMESPACE}"
echo "Or watch task runs and pod logs via kubectl/kns or tkn if installed:"
echo "  tkn pipelinerun logs --follow <pipelinerun-name> -n ${NAMESPACE}"

exit 0
