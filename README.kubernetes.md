# EduChat Deployment — Helm / Kubernetes

> Helm chart that deploys the EduChat application on the K3s cluster configured by Ansible.
> **Step 3/3** — requires a running K3s cluster ([README.ansible.md](README.ansible.md))

---

## Overview

```
Internet
    │ :80
    ▼
Traefik Ingress (K3s built-in)
    │
    ├── /        → edu-service-frontend  :80 → Vue.js pod       :5173
    └── /api     → edu-service-backend   :80 → FastAPI pods x2  :8000
                                                    │
                                         ┌──────────┼──────────┐
                                         ▼          ▼          ▼
                                    PostgreSQL    Redis    Playwright
                                    (ClusterIP)  (ClusterIP)  (always-on)
                                      :5432       :6379
```

---

## Chart structure

```
azure-kubernetes/
├── Chart.yaml              # Chart metadata (name, version)
├── values.yaml             # Single source of truth — all variables
├── values.secret.yaml      # Passwords — NEVER commit
└── templates/
    ├── app-config.yaml     # ConfigMap — environment variables
    ├── app-secrets.yaml    # Secret — PostgreSQL credentials
    ├── namespace.yaml      # Namespace dev
    ├── deployment-backend.yaml
    ├── deployment-frontend.yaml
    ├── deployment-postgres.yaml
    ├── deployment-redis.yaml
    ├── service-backend.yaml
    ├── service-frontend.yaml
    ├── service-postgres.yaml
    ├── service-redis.yaml
    └── ingress.yaml
```

---

## values.yaml — Single source of truth

All shared values are centralized here. Changing a value propagates automatically to every template.

| Section | Key | Example |
|---------|-----|---------|
| `app.name` | Prefix for all resource names | `edu` |
| `namespace` | Kubernetes namespace | `dev` |
| `ingress.className` | Ingress controller | `traefik` |
| `replicas.backend` | Number of backend pods | `2` |
| `images.backend` | Backend Docker image | `ghcr.io/0xcaf3d0od/edu-backend:latest` |
| `ports.backend` | Backend application port | `8000` |
| `services.backend` | Backend service name | `service-backend` |

> All resource names follow the pattern: `{{ app.name }}-{{ services.X }}`
> Example: `edu-service-backend`

---

## Services

| Service | Type | Exposed port | App port |
|---------|------|-------------|----------|
| `edu-service-frontend` | ClusterIP | 80 | 5173 |
| `edu-service-backend` | ClusterIP | 80 | 8000 |
| `edu-service-postgres` | ClusterIP | 5432 | 5432 |
| `edu-service-redis` | ClusterIP | 6379 | 6379 |

> PostgreSQL and Redis are ClusterIP only — reachable inside the cluster, not from outside.

---

## Environment variables injected into pods

Pods receive their configuration from two K8s resources:

**ConfigMap `educhat-config`** — non-sensitive values
```
FASTAPI_HOST         = edu-service-backend
FASTAPI_PORT         = 8000
REDIS_HOST           = edu-service-redis
REDIS_PORT           = 6379
POSTGRES_HOST        = edu-service-postgres
POSTGRES_PORT        = 5432
POSTGRES_DB          = educhat-db
VUEJS_PORT           = 5173
```

**Secret `educhat-secret`** — sensitive values (base64-encoded internally)
```
POSTGRES_USER        → values.secret.yaml
POSTGRES_PASSWORD    → values.secret.yaml
```

---

## Useful commands

```bash
# On the master VM (ssh adminuser@<PUBLIC_IP>)
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Overall cluster state
sudo kubectl get all -n dev

# Pods with node placement
sudo kubectl get pods -n dev -o wide

# Check ingress
sudo kubectl get ingress -n dev

# Stream pod logs
sudo kubectl logs -f pod/edu-deployment-backend-XXXXX -n dev

# Describe a failing pod
sudo kubectl describe pod edu-deployment-backend-XXXXX -n dev
```

**From your local machine (with Helm):**
```bash
# Redeploy after modifying values.yaml
helm upgrade educhat ./azure-kubernetes \
  --namespace dev \
  --values azure-kubernetes/values.yaml \
  --values azure-kubernetes/values.secret.yaml

# List deployed Helm releases
helm list -n dev

# Uninstall
helm uninstall educhat -n dev
```

---

## Resource limits per pod

Defined globally in `values.yaml` and applied to every deployment:

| | CPU | Memory |
|-|-----|--------|
| **Request** (guaranteed) | 100m | 128 Mi |
| **Limit** (maximum) | 500m | 256 Mi |

---

## Known issues

**`CLASS: nginx` → ingress has no address**
K3s ships with Traefik, not Nginx. Make sure `ingress.className` is set to `traefik` in `values.yaml`.

**`ImagePullBackOff` — 401 Unauthorized**
Private GHCR images fail without credentials. Make the packages public on GitHub or create an `imagePullSecret`:
```bash
sudo kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=0xCAF3D0OD \
  --docker-password=TOKEN \
  --namespace=dev
```
Then reference `imagePullSecrets` in each deployment.

**PostgreSQL with `replicas > 1` — risk of data corruption**
Standalone PostgreSQL cannot run multiple write instances against the same volume. Keep `replicas: 1`. For high availability, use Patroni or Azure Database for PostgreSQL.

**Ansible does not detect pod failures after deploy**
`helm upgrade` exits 0 even if pods crash afterward. To catch this automatically, add to the playbook:
```yaml
- name: Wait for pods to be ready
  ansible.builtin.command:
    cmd: kubectl wait --for=condition=ready pod --all -n dev --timeout=120s
  environment:
    KUBECONFIG: /etc/rancher/k3s/k3s.yaml
```

---

## Expected state after a successful deployment

```bash
sudo kubectl get all -n dev
```

```
NAME                                           READY   STATUS    RESTARTS
pod/edu-deployment-backend-XXXXX              1/1     Running   0
pod/edu-deployment-backend-YYYYY              1/1     Running   0
pod/edu-deployment-frontend-XXXXX             1/1     Running   0
pod/edu-deployment-postgres-XXXXX             1/1     Running   0
pod/edu-deployment-redis-XXXXX                1/1     Running   0

NAME                           TYPE        CLUSTER-IP     PORT(S)
service/edu-service-backend    ClusterIP   10.43.x.x      80/TCP
service/edu-service-frontend   ClusterIP   10.43.x.x      80/TCP
service/edu-service-postgres   ClusterIP   10.43.x.x      5432/TCP
service/edu-service-redis      ClusterIP   10.43.x.x      6379/TCP
```

Application reachable at `http://<MASTER_VM_PUBLIC_IP>`
