# Shadowsocks deployment for Computer Engine in GCP

This project automates the deployment of a containerized Shadowsocks and V2Ray application stack on Google Cloud Platform (GCP). It utilizes Terraform to provision an optimized virtual machine, configures dedicated VPC networking with static public IP addressing, dynamically applies multi-protocol firewall rules, and securely injects rendered Docker Compose configurations and local TLS certificates via instance metadata for zero-touch deployment.

---

## 🏗️ Architecture & Features

- **GCP Infrastructure**: Highly configurable deployment (default: `e2-micro` in `us-west1-c`).
- **OS Image**: Debian 12 Bookworm (`debian-cloud/debian-12`) — lightweight, stable, and memory-optimized for small VM instances.
- **Dedicated VPC & Dynamic Firewall**:
  - Automatically provisions an isolated custom VPC network.
  - Dynamically builds TCP and UDP firewall rules from variable maps:
    - **Standard Web**: TCP `80`, `443`
    - **Custom Services**: TCP `8080`, `9000` & UDP `9000`
    - **Management**: TCP `22` (SSH)
- **Automated Security & Secrets Management**:
  - Generates cryptographically secure random passwords for V2Ray, V2Ray-QUIC, V2Ray-gRPC, and HTTP proxy services.
  - Exports generated credentials locally to `configs/passwords.json` with restricted permissions (`0600`).
- **Zero-Touch Container Orchestration**:
  - Renders `docker-compose.yml` dynamically using `templatefile` (injecting Shadowsocks configurations, Cloudflare Tunnel tokens, and local ACME SSL certificates).
  - Automatically installs Debian-specific Docker Engine and Docker Compose plugins via GCP startup scripts and launches the stack (`docker compose up -d`).

---

## 📂 Project Structure

```text
├── configs/
│   ├── passwords.json          # Auto-generated sensitive credentials (ignored by Git)
│   └── production.tfvars       # Environment-specific variable definitions
├── keys/
│   ├── private.key             # Local SSL/TLS private key
│   └── fullchain.crt           # Local SSL/TLS fullchain certificate
├── docker-compose.yml.tftpl    # Docker Compose Terraform template
├── main.tf                     # Compute Engine, VPC, Firewall, and Data Sources
├── variables.tf                # Input variables with strict typing and descriptions
├── provider.tf                 # GCP Provider configuration
└── README.md                   # Project documentation
---

## 🚀 Quick Start & CLI Operations

Follow these shell commands to authenticate with Google Cloud, configure project quotas, apply infrastructure changes, and access the deployed instance. All command comments are provided in English as specified.

```shell
# Install gcloud-cli
# Refer to the official Google Cloud documentation for OS-specific installation instructions.

# Authenticate via browserless flow
gcloud auth application-default login --no-launch-browser

# Set project ID for Application Default Credentials
gcloud auth application-default set-quota-project <project-id> 

# Provision resources using specified variable configuration file
terraform apply -var-file=configs/<config>.tfvars --auto-approve

# Authenticate user account
gcloud auth login

# Set active GCP project ID
gcloud config set project <project-id>

# SSH into VM
gcloud compute ssh --zone=us-west1-c docker-compose-vm

# View startup script execution logs
sudo journalctl -u google-startup-scripts.service -f