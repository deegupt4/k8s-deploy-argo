# ArgoCD Multi-Cluster Multi-Environment Deployment Repository

## Directory Structure

```
k8s-deployments/
├── app-of-apps/          # Bootstrap - Entry point for ArgoCD
│   └── clusters/
│       ├── dev-argocd/   # Dev ArgoCD hub manages dev clusters
│       ├── prod-argocd/  # Prod ArgoCD hub manages prod clusters
│       └── sbx-argocd/   # Sandbox ArgoCD hub manages sbx clusters
│
├── apps/                 # Application definitions per cluster
│   └── clusters/
│       ├── dev-cluster-a/
│       ├── dev-cluster-b/
│       ├── prod-cluster-a/
│       ├── prod-cluster-b/
│       ├── sbx-cluster-a/
│       └── ...
│
├── infra-apps/           # Infrastructure apps (cert-manager, external-secrets, etc.)
│   └── clusters/
│       └── ...
│
├── projects/             # ArgoCD AppProjects for RBAC
│   ├── base/
│   └── clusters/
│
└── manifests/            # Helm values and configs per app
    └── <app-name>/
        ├── base/
        └── clusters/
```

## Environments

| Environment | ArgoCD Hub      | Managed Clusters                    |
|-------------|-----------------|-------------------------------------|
| dev         | dev-argocd      | dev-cluster-a, dev-cluster-b        |
| prod        | prod-argocd     | prod-cluster-a, prod-cluster-b      |
| sbx         | sbx-argocd      | sbx-cluster-a                       |

## Bootstrap a Cluster

```bash
kubectl apply -k app-of-apps/clusters/<argocd-hub-cluster>
```

## Adding a New Application

1. Create AppProject in `projects/base/<project>.yaml`
2. Create Application/ApplicationSet in `apps/clusters/<cluster>/<app>/`
3. Add Helm values in `manifests/<app>/clusters/<cluster>/`
