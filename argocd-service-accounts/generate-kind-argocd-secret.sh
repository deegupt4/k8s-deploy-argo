#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# This script is ONLY for KIND clusters.
# It discovers the Kubernetes API server via Docker control-plane container IP.
###############################################################################

usage() {
  echo "Usage: $0 -c <kubectl-context> -n <argocd-cluster-name>"
  echo ""
  echo "  -c   kubectl context of KIND cluster (e.g. kind-dev-2)"
  echo "  -n   name shown in ArgoCD UI (e.g. dev2)"
  exit 1
}

while getopts "c:n:" opt; do
  case "$opt" in
    c) CONTEXT="$OPTARG" ;;
    n) ARGO_CLUSTER_NAME="$OPTARG" ;;
    *) usage ;;
  esac
done

[[ -z "${CONTEXT:-}" || -z "${ARGO_CLUSTER_NAME:-}" ]] && usage

echo "▶ Using context: $CONTEXT"

# ---------------------------------------------------------------------------
# Switch kubectl context
# ---------------------------------------------------------------------------
kubectl config use-context "$CONTEXT" >/dev/null

# ---------------------------------------------------------------------------
# Apply ServiceAccount / RBAC (local file)
# ---------------------------------------------------------------------------
kubectl apply -f sa.yaml

echo "▶ Waiting for service account token..."
sleep 3

# ---------------------------------------------------------------------------
# Get SA token secret
# ---------------------------------------------------------------------------
SECRET_NAME=$(kubectl get secret -n argocd \
  -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='argocd-manager')].metadata.name}")

if [[ -z "$SECRET_NAME" ]]; then
  echo "❌ argocd-manager token secret not found"
  exit 1
fi

TOKEN=$(kubectl get secret "$SECRET_NAME" -n argocd \
  -o jsonpath="{.data.token}" | base64 -d)

CA=$(kubectl get secret "$SECRET_NAME" -n argocd \
  -o jsonpath="{.data['ca\.crt']}")

# ---------------------------------------------------------------------------
# KIND-specific API server detection (Docker)
# ---------------------------------------------------------------------------
CONTROL_PLANE_CONTAINER="${CONTEXT#kind-}-control-plane"

echo "▶ Detecting KIND API server from Docker container: $CONTROL_PLANE_CONTAINER"

SERVER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  "$CONTROL_PLANE_CONTAINER")

if [[ -z "$SERVER_IP" ]]; then
  echo "❌ Failed to detect Docker IP for $CONTROL_PLANE_CONTAINER"
  exit 1
fi

SERVER="https://${SERVER_IP}:6443"

echo "▶ Server detected: $SERVER"

# ---------------------------------------------------------------------------
# Generate ArgoCD cluster secret
# ---------------------------------------------------------------------------
OUTPUT="argocd-cluster-${ARGO_CLUSTER_NAME}.yaml"

cat <<EOF > "$OUTPUT"
apiVersion: v1
kind: Secret
metadata:
  name: argocd-cluster-${ARGO_CLUSTER_NAME}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${ARGO_CLUSTER_NAME}
  server: ${SERVER}
  config: |
    {
      "bearerToken": "${TOKEN}",
      "tlsClientConfig": {
        "caData": "${CA}",
        "insecure": false
      }
    }
EOF

echo "✅ Generated: $OUTPUT"
echo ""
echo "👉 Apply this on the ArgoCD (prod) cluster:"
echo "   kubectl apply -f $OUTPUT"
