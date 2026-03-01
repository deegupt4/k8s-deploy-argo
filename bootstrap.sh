#!/bin/bash

# Bootstrap script for ArgoCD multi-cluster setup
# Usage: ./bootstrap.sh <argocd-hub-cluster>
# Example: ./bootstrap.sh dev-argocd

set -e

ARGOCD_HUB=${1:-"dev-argocd"}

echo "Bootstrapping ArgoCD for hub: $ARGOCD_HUB"

# Create argocd namespace if not exists
kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -

# Apply AppProjects
echo "Applying AppProjects..."
kubectl apply -k projects/base

# Apply App-of-Apps
echo "Applying App-of-Apps for $ARGOCD_HUB..."
kubectl apply -k app-of-apps/clusters/$ARGOCD_HUB

echo "Bootstrap complete for $ARGOCD_HUB"
echo ""
echo "Managed clusters:"
ls -1 app-of-apps/clusters/$ARGOCD_HUB/*.yaml | grep -v kustomization | xargs -I {} basename {} .yaml
