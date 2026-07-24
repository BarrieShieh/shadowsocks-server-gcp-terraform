# GCP Shadowsocks Server with Terraform

An automated Infrastructure-as-Code (IaC) project to deploy and manage a secure [Shadowsocks](https://shadowsocks.org/) proxy server on Google Cloud Platform (GCP) using [Terraform](https://www.terraform.io/).

---

## Overview

This repository provides a fully automated setup for running a containerized Shadowsocks server on a GCP Compute Engine instance. It automatically provisions the necessary virtual network, configures ingress/egress firewall rules, boots a Virtual Machine (VM), and initializes the Shadowsocks service upon startup.

## Features

- **Automated Infrastructure:** Zero-touch provisioning and teardown using standard Terraform workflows.
- **Firewall & Security Configuration:** Configures specific GCP Compute Firewall ingress rules for Shadowsocks traffic, SSH access, and ICMP health checks.
- **Multi-Plugin Support:** Native support for various Shadowsocks plugins and transports (e.g., v2ray-plugin with WebSockets/gRPC/QUIC, TLS obfs, and Cloudflare Tunnels).
- **Dockerized Setup:** Runs the Shadowsocks service via Docker inside the instance for isolation, stability, and easy updates.
- **Flexible Parameters:** Customizable server specs, region/zone selection, proxy listening ports, passwords, and encryption ciphers via Terraform variables.

---

## Prerequisites

Ensure you have installed and configured the following tools on your local machine:

1. **[Terraform](https://developer.hashicorp.com/terraform/downloads)** (v1.0.0 or higher)
2. **[Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install)**
3. An active **GCP Project** with billing enabled.

---

## Configuration

Before applying your infrastructure, create or customize a `.tfvars` file under the `configs/` directory (e.g., `configs/prod.tfvars`). This file defines your target GCP project, enabled services, plugin configurations, and custom firewall rules.

### Example `tfvars` Configuration

```hcl
# ==============================================================================
# GENERAL & PROVIDER SETTINGS
# ==============================================================================

# Target Google Cloud Project ID where infrastructure will be deployed
gcp_project_id = "your-gcp-project-id"

# Base domain name (managed via Cloudflare DNS)
domain = "example.com"

# Cloudflare credentials for DNS record management and Zero Trust tunnels
cloudflare_account_id = "your-cloudflare-account-id"
cloudflare_api_token  = "your-cloudflare-api-token"

# Email address used for ACME / Let's Encrypt TLS certificate registration
email_address = "admin@example.com"

# Optional additional DNS subdomains to bind to this deployment
additional_subdomain = ["test2"]

# ==============================================================================
# SERVICES CONFIGURATION
# ==============================================================================
/*
  Cloudflare Default Proxied Ports Reference:
  - HTTP:  80, 8080, 8880, 2052, 2082, 2086, 2095
  - HTTPS: 443, 2053, 2083, 2087, 2096, 8443
*/
services = {
  # Direct TLS service
  tls = {
    enabled     = false
    method      = "2022-blake3-aes-256-gcm"
    server_port = 80
  }

  # WebSocket service routed via Cloudflare Tunnel
  ws = {
    enabled       = true
    subdomain     = "test1"
    path          = "/ws"
    method        = "2022-blake3-aes-256-gcm"
    server_port   = 443
    create_tunnel = true
  }

  # gRPC transport service
  grpc = {
    enabled     = true
    method      = "2022-blake3-aes-256-gcm"
    server_port = 8443
  }

  # QUIC / UDP transport service
  quic = {
    enabled     = true
    method      = "2022-blake3-aes-256-gcm"
    server_port = 2053
  }

  # Cloudflare Tunnel daemon container
  cloudflared = {
    enabled = true
  }

  # Caddy reverse proxy web server container
  caddy = {
    enabled = true
  }
}
```

---

## 🚀 Quick Start & CLI Operations

Follow these shell commands to authenticate with Google Cloud, initialize Terraform, apply infrastructure changes, and access the deployed instance. All command comments are provided in English.

```shell
# Install gcloud-cli
# Refer to the official Google Cloud documentation for OS-specific installation instructions.

# Authenticate via browserless flow
gcloud auth application-default login --no-launch-browser

# Set project ID for Application Default Credentials
gcloud auth application-default set-quota-project <project-id>

# Initialize Terraform modules and providers
terraform init

# Provision resources using the customized configuration file
terraform apply -var-file=configs/prod.tfvars --auto-approve

# Authenticate user account for Compute Engine operations
gcloud auth login

# Set active GCP project ID
gcloud config set project <project-id>

# SSH into the deployed VM instance
gcloud compute ssh --zone=us-west1-c docker-compose-vm

# View startup script execution logs in real time
sudo journalctl -u google-startup-scripts.service -f
```

---

## Cleanup / Teardown

To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

```bash
terraform destroy -var-file=configs/prod.tfvars
```

Confirm with `yes` when prompted.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
