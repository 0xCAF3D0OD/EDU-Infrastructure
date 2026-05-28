# VM Configuration — Ansible

> Installs K3s, Helm, and deploys EduChat on the VMs provisioned by Terraform.
> **Step 2/3** — requires VMs created by [README.terraform.md](README.terraform.md). Deploys the chart described in [README.kubernetes.md](README.kubernetes.md)

---

## Overview

```
Ansible (from your local machine)
│
├── Play 1 — Install K3s master
│   └── vm-dev-1 → K3s server (control-plane)
│
├── Play 2 — Install K3s workers
│   └── vm-dev-2 → K3s agent
│
├── Play 3 — Verify cluster
│   └── kubectl get nodes → waits until all nodes are Ready
│
├── Play 4 — Install Helm
│   └── vm-dev-1 → Helm installed + chart files copied
│
└── Play 5 — Deploy EduChat
    └── helm upgrade --install educhat → namespace dev
```

---

## Requirements

| Tool | Notes |
|------|-------|
| Ansible | >= 2.12 |
| Role `xanmanning.k3s` | Present in `roles/` |
| SSH private key | `~/.ssh/azure_ssh_key.pem` |
| Azure VMs running | See [README.terraform.md](README.terraform.md) |

---

## File structure

```
azure-ansible/educhat/
├── ansible.cfg                        # Global Ansible configuration
├── kube.playbook.yaml                 # Main playbook
└── inventories/
    └── home/
        └── hosts.yaml                 # VM IPs + K3s groups
```

---

## Inventory — hosts.yaml

```
k3s
├── k3s_master
│   └── master.lab.example.com  (vm-dev-1 — 4.155.235.16)
│       └── k3s_cluster_init: true
│           max-pods: 110
└── k3s_workers
    └── worker-01.lab.example.com  (vm-dev-2 — 20.9.170.184)
        └── k3s_server_url: https://4.155.235.16:6443
            max-pods: 45
```

> After each `terraform apply`, update the `ansible_host` values with the new public IPs.

---

## Playbook tags

| Tag | What it runs |
|-----|-------------|
| `k3s` | All K3s plays (master + workers + verify) |
| `master` | Install K3s on master only |
| `workers` | Install K3s on workers only |
| `verify` | Check that all nodes are Ready |
| `helm` | Install Helm + copy chart files |
| `install` | Install Helm + copy (no deploy) |
| `deploy` | Helm deployment only |

---

## Commands

```bash
cd azure-ansible/educhat

# Check SSH connectivity to all VMs
ansible all -m ping

# Full deployment (first time)
ansible-playbook kube.playbook.yaml

# Redeploy the app only (K3s and Helm already installed)
ansible-playbook kube.playbook.yaml --tags "helm,deploy"

# Install K3s only
ansible-playbook kube.playbook.yaml --tags "k3s"
```

---

## What each play does

**Play 1 & 2 — K3s**
Uses the `xanmanning.k3s` role. Installs K3s in server mode on `vm-dev-1` and agent mode on `vm-dev-2`. The worker connects to the master automatically via `k3s_server_url`.

**Play 3 — Verify**
Polls `kubectl get nodes` every 10 seconds until no node is in `NotReady` state. Times out after 5 minutes.

**Play 4 — Helm**
Downloads the official Helm install script, runs it on the master, then copies the `azure-kubernetes/` directory (Helm chart) to `/home/adminuser/azure-kubernetes/` on the VM.

**Play 5 — Deploy**
Creates the `dev` namespace (ignores error if it already exists), then runs `helm upgrade --install educhat` with both `values.yaml` and `values.secret.yaml`.

---

## Sensitive files

`values.secret.yaml` contains PostgreSQL passwords. It is excluded from git (`.gitignore`) but **must be present locally** before running the playbook, as Ansible copies it from your disk to the VM.

```
azure-kubernetes/values.secret.yaml   ← local only, never committed
```

---

## Known issues

**`namespaces "dev" already exists`**
The deploy play creates the namespace with `kubectl create namespace dev` before Helm (`failed_when: false`). If the error persists, remove `--create-namespace` from the Helm command — the kubectl task is sufficient.

**`permission denied` on `/etc/rancher/k3s/k3s.yaml`**
K3s creates the kubeconfig as root-only. Fix it once on the VM:
```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```
Or always use `sudo kubectl`.

**`ImagePullBackOff` on first deploy**
Private GHCR images require authentication. Either make the packages public on GitHub (Packages → Change visibility) or create an `imagePullSecret` in K8s.

**Ansible marks read-only tasks as `changed`**
Add `changed_when: false` to any `shell`/`command` task that only reads state and makes no changes.

---

## Next step

Once the playbook completes without errors:

```bash
# Verify on the VM
ssh -i ~/.ssh/azure_ssh_key.pem adminuser@4.155.235.16
sudo kubectl get all -n dev
```

All pods should be `Running` → [README.kubernetes.md](README.kubernetes.md)
