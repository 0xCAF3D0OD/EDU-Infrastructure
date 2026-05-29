# Azure Infrastructure — Terraform

> Provisions 2 Ubuntu 22.04 VMs on Azure with networking, security rules, and static public IPs.
> **Step 1/3** of the EduChat deployment — see also [README.ansible.md](README.ansible.md) and [README.kubernetes.md](README.kubernetes.md)

---

## Overview

```
Terraform
│
├── Resource Group (myTFResourceGroup)
│   ├── VNet (10.0.0.0/16)
│   │   └── Subnet (10.0.2.0/24)
│   │
│   ├── vm-dev-1  ──── NIC ──── pip-vm1 (static public IP)
│   ├── vm-dev-2  ──── NIC ──── pip-vm2 (static public IP)
│   │
│   └── NSG (rules: SSH 22, HTTP 80, HTTPS 443)
```

---

## Requirements

| Tool | Minimum version |
|------|----------------|
| Terraform | >= 1.1.0 |
| Azure CLI | any |
| SSH key | `~/.ssh/azure_ssh_key.pub` + `azure_ssh_key.pem` |

Authenticate with Azure before running any command:
```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

---

## File structure

```
azure-terraform/
├── main.tf        # Azure provider + Resource Group
├── variables.tf   # Input variables (region, VM size, SSH key...)
├── compute.tf     # VM definitions
├── network.tf     # VNet, Subnet, NICs, public IPs
├── security.tf    # NSG + inbound rules
└── outputs.tf     # Exported public/private IPs
```
Reading workflow:
```
variables.tf   → configurable settings
    ↓
main.tf        → provider + global container
    ↓
network.tf     → network (VNet → Subnet → IPs → NICs)
    ↓
security.tf    → firewall applied to NICs
    ↓
compute.tf     → VMs that consume everything else
    ↓
outputs.tf     → values exported after deployment
```


---

## Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `West US 2` | Azure region |
| `vm_count` | `2` | Number of VMs |
| `vm_size` | `Standard_D2als_v7` | VM size (2 vCPU, 8 GB RAM) |
| `subscription_id` | — | **Required**, no default |
| `environment` | `dev` | Prefix for all resource names |

> Sensitive variables (`subscription_id`, `client_id`, `client_secret`, `tenant_id`) must never be committed. Use a `terraform.tfvars` file excluded from git.

---

## Commands

```bash
# Initialize providers
terraform init

# Preview changes before applying
terraform plan

# Deploy infrastructure
terraform apply

# Retrieve VM public IPs (needed for Ansible inventory)
terraform output vm_public_ips

# Destroy all resources
terraform destroy
```

---

## Available outputs

| Output | Description |
|--------|-------------|
| `vm_public_ips` | Public IPs → copy into Ansible `hosts.yaml` |
| `vm_private_ips` | Internal IPs (inter-VM communication) |
| `vm_names` | Names of created VMs |
| `resource_group_name` | Resource Group name |
| `nsg_id` | Network Security Group ID |

---

## Network security rules (NSG)

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH — Ansible access + admin |
| 80 | TCP | HTTP — Traefik Ingress |
| 443 | TCP | HTTPS — future SSL/TLS |

> ⚠️ Port 22 is open to `0.0.0.0/0`. In production, restrict to your own IP.

---

## Known issues

**VM SKU unavailable in the selected region**
SKU availability varies by region. If `Standard_D2als_v7` is unavailable, change `location` in `variables.tf` or pick a different SKU. You can check availability with:
```bash
az vm list-skus --location "West US 2" --size Standard_D2als --output table
```

**Gen 1 vs Gen 2 image incompatibility**
`Standard_D2als_v7` is a Generation 2 VM. The OS image must also be Gen 2. The current configuration uses `22_04-daily-lts-gen2` which is correct. If you change the VM size or image, make sure the hypervisor generation matches — mixing them causes an immediate error on `terraform apply`.

**SSH private key permissions too open**
If Ansible or SSH refuses the private key with a `bad permissions` warning, the file is readable by others. Fix it once:
```bash
chmod 400 ~/.ssh/azure_ssh_key.pem
```
This is required — SSH will silently ignore keys with permissions wider than `400`.

**`resource_provider_registrations = "none"` in provider block**
Prevents permission errors on restricted Azure subscriptions. Do not remove.

**Public IP shows `null` after `terraform apply`**
Azure can take a few seconds to assign IPs. Re-run `terraform output vm_public_ips`.

---

## Next step

Once `terraform apply` completes:

1. Copy the public IPs: `terraform output vm_public_ips`
2. Update `azure-ansible/educhat/inventories/home/hosts.yaml`
3. Continue to step 2 → [README.ansible.md](README.ansible.md)
