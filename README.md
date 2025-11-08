Markdown

# Kraken: K3s Homelab GitOps Repository

This repository is the single source of truth for my hybrid-architecture k3s homelab cluster, **kraken**. It strictly follows the GitOps pattern, meaning the entire state of the cluster is defined here and automatically synced by ArgoCD.

The goal of this project is to build a professional-grade, automated platform for learning and experimentation. It is built on "best-practice" enterprise tools to mirror a real-world DevOps environment.

## 🏗️ Hardware Architecture

Kraken runs on a diverse, hybrid mix of hardware, leveraging the strengths of each platform:

### Control Plane (HA)
* **2x Proxmox VMs**: (4GB RAM, 2 vCPU) - Running on separate physical Proxmox servers for true redundancy.
* **1x HP Desk Mini 800 G2**: (8GB RAM) - Acts as a physical anchor for the control plane.
* *All 3 nodes run dedicated etcd for a highly available quorum.*

### Data Plane (Workers)
* **3x HP Desk Mini 800 G2**: (8GB RAM, 500GB dedicated NVMe) - Primary compute nodes. NVMe drives are dedicated to Longhorn for high-performance distributed storage.
* **4x Raspberry Pi 4**: (4GB RAM, USB Boot SSD) - ARM64 compute nodes for specialized workloads and edge testing.

## 🚀 Core Technology Stack

The platform is built in two distinct layers:

### 1. Infrastructure (Provisioning)

* **Hypervisor:** Proxmox VE
* **VM Automation:** Packer (Templates) & Terraform (Deployment)
* **Physical Automation:** PXE Boot with Preseed configuration (fully automated bare-metal install)
* **Kubernetes Distribution:** K3s (lightweight, perfect for this hybrid mix)

### 2. Kubernetes Platform (GitOps)

* **GitOps Controller:** ArgoCD (App-of-Apps pattern)
* **Ingress Controller:** ingress-nginx (with MetalLB for LoadBalancing)
* **Persistent Storage:** Longhorn (Distributed Block Storage on NVMe) & NFS (TrueNAS integration)
* **SSL/TLS Automation:** cert-manager (Let's Encrypt DNS-01 via Cloudflare)
* **Secret Management:** Sealed Secrets (Encryption at rest in Git)
* **Secret Distribution:** Reflector (Auto-copies wildcard certs across namespaces)

## 🗺️ Future Roadmap

* **[TODO] Migrate Secret Management:** Transition from Sealed Secrets to HashiCorp Vault with External Secrets Operator (ESO) for enterprise-grade secret rotation and dynamic secrets.

## 📁 Repository Structure

This repository uses a multi-tiered ArgoCD "App of Apps" pattern to separate low-level infrastructure from high-level user applications.

```bash
.
├── bootstrap/
│   └── root-platform.yaml   # The ONLY file applied manually. Kicks off everything.
├── infrastructure/          # Layer 1: Core cluster services (Storage, Networking, Security)
│   ├── argocd-ingress/      # Application: Exposes ArgoCD UI via HTTPS
│   ├── cert-manager/        # Application: Manages SSL certificates
│   ├── longhorn/            # Application: Distributed block storage
│   ├── sealed-secrets/      # Application: Decrypts secrets stored in Git
│   └── ...
├── platform/                # Layer 2: User-facing applications (Plex, Nextcloud, etc.)
│   ├── ...
└── configs/                 # The actual Kubernetes manifests (Payloads)
    ├── argocd-ingress/      # Ingress route for ArgoCD
    ├── certificates/        # Wildcard Certificate definitions
    ├── nfs-volumes/         # PV/PVC definitions for TrueNAS
    └── ...

How It Works

    bootstrap/root-platform.yaml: This is the master parent application. It watches the infrastructure/ and platform/ directories.

    infrastructure/: Contains ArgoCD Application manifests. These define how and when (sync waves) to deploy core services.

    configs/: Contains the actual raw Kubernetes manifests (Ingresses, Services, PVCs) that the infrastructure apps deploy.

⚡ How to Bootstrap

To bootstrap a fresh, empty cluster to this exact state, only one command is required after installing ArgoCD:
Bash

kubectl apply -f bootstrap/root-platform.yaml

ArgoCD will then automatically:

    Detect all applications in infrastructure/.

    Deploy them in the correct order using Sync Waves (e.g., Storage → Networking → Security → Apps).

    Once infrastructure is healthy, it will start deploying user apps from platform/.

🔒 Secrets Management

This repository does not contain plaintext secrets.

    Sealed Secrets: All sensitive data (API tokens, passwords) is encrypted into SealedSecret resources that can only be decrypted by the controller running inside the Kraken cluster.

    Reflector: Automatically mirrors standard Kubernetes Secrets (like our wildcard TLS certificate) from a central namespace to all other namespaces that need them
