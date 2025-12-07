# Learn Terraform Pipelines - Kubernetes

This repo is a companion repo to the [Deploy Consul and Vault on Kubernetes with Run Triggers](https://learn.hashicorp.com/tutorials/terraform/kubernetes-consul-vault-pipeline?in=terraform/kubernetes), containing Terraform configuration files to provision an GKE cluster on GCP.

## PoW security hardening

The configuration now ships with "Protect-our-Workloads (PoW)" guardrails enabled by default. Highlights:

- Workload Identity ties Kubernetes service accounts to Google service accounts and is enforced via Binary Authorization and Shielded Nodes.
- Security posture scanning (basic mode) is enabled on the cluster, together with the advanced datapath.
- Node pools enforce `GKE_METADATA` node metadata, secure boot, and integrity monitoring for each node.

These settings can be toggled with the `enable_pow_security` variable, but Sentinel enforces them by default to prevent accidental drift.

## Sentinel policy

The repo includes a `pow-security` Sentinel policy (`sentinel/pow-security.sentinel`) wired up through `sentinel.hcl`. To evaluate it locally:

1. `terraform plan -out=tfplan.binary`
2. `terraform show -json tfplan.binary > tfplan.json`
3. `sentinel apply -config=sentinel.hcl tfplan.json`

Terraform Cloud/Terraform Enterprise users can upload both files to enforce PoW security in their runs.
