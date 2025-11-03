Here is the updated README.md, rewritten to reflect your cluster's name, "kraken".

Kraken: K3s Homelab GitOps Repository

This repository is the single source of truth for my k3s homelab cluster, kraken. It follows the GitOps pattern, meaning the state of this repo is automatically synced to the cluster by ArgoCD.

The goal of this project is to build a professional-grade, automated platform for learning and experimentation, from the underlying virtual machines to the deployed applications. The entire platform is built on "best-practice" and enterprise-grade tools to mirror a real-world DevOps environment.

🚀 Core Technology Stack

This platform is built in two layers:

1. Infrastructure (Provisioning)

    Hypervisor: Proxmox

    VM Templates: Packer

    VM Deployment: Terraform

    OS Installation: PXE Boot & Pre-seed configuration

2. Kubernetes Platform (GitOps)

    Distribution: k3s (running the kraken cluster)

    GitOps Controller: ArgoCD

    Secret Management: HashiCorp Vault

    Secrets Bridge: External Secrets Operator (ESO)

    Ingress (Reverse Proxy): ingress-nginx

    SSL Certificates: cert-manager (with Let's Encrypt)

    Automatic DNS: ExternalDNS (integrated with Cloudflare)

    Persistent Storage: Longhorn

📁 Repository Structure

This repository uses the ArgoCD "App of Apps" pattern.

.
├── .gitignore
├── platform/               # 1. Contains all child app manifests (Vault, Longhorn, ArgoCD, etc.)
├── README.md
└── root-platform.yaml      # 2. The ONLY file to apply manually. This is the parent "App of Apps".

    root-platform.yaml: This is the parent application. Its only job is to watch the platform/ directory.

    platform/: This directory contains the ArgoCD Application manifests for every other piece of our platform (Vault, Cert-Manager, our apps, etc.). When a file is added to this directory and pushed to main, ArgoCD will automatically see it and deploy it.

⚡ How to Bootstrap

To bootstrap a new, empty k3s cluster to this repository's state, only one manual command is required.

    Set up SSH Access: (Instructions to be added for giving ArgoCD read access to this private repository).

    Apply the Root App: This command tells ArgoCD to start monitoring this repo and build the kraken cluster.
    Bash

    kubectl apply -f root-platform.yaml

From this point on, all other applications will be deployed automatically by ArgoCD.

🔒 Secrets Management

This repository MUST NOT contain any plaintext secrets, API keys, or passwords.

All secrets for the kraken cluster are managed externally using HashiCorp Vault.

Workflow:

    A secret (e.g., a Cloudflare API token) is stored securely in Vault.

    An application manifest in the platform/ directory will include an ExternalSecret resource.

    The External Secrets Operator (ESO), which is running in the cluster, will see this resource.

    ESO will securely connect to Vault, fetch the secret, and create a native Kubernetes Secret in the correct namespace.

    Our applications (like cert-manager or ExternalDNS) will mount this native Kubernetes Secret and function normally.

ArgoCD only ever syncs the request for a secret (ExternalSecret), not the secret itself.
