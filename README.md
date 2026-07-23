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
# Target GCP Project ID
project_id = "cloud-162606"

# Service configurations for Shadowsocks and its plugins
services = {
  tls = {
    enabled     = true
    method      = "2022-blake3-aes-256-gcm"
    server_port = 80
  }
  v2ray-ws = {
    enabled     = false
    method      = "2022-blake3-aes-256-gcm"
    server_port = 9000
  }
  v2ray-grpc = {
    enabled     = true
    host        = "<host>"
    method      = "2022-blake3-aes-256-gcm"
    server_port = 443
  }
  v2ray-quic = {
    enabled     = false
    host        = "<host>"
    method      = "2022-blake3-aes-256-gcm"
    server_port = 443
  }
  cloudflared = {
    enabled = false
  }
}

# Custom GCP Compute Firewall rules
firewall_rules = {
  v2ray-quic = {
    name          = "v2ray-quic"
    priority      = 1000
    direction     = "INGRESS"
    target_tags   = ["v2ray-quic"]
    source_ranges = ["0.0.0.0/0"]
    allow = [
      {
        protocol = "tcp"
        ports    = ["8080"]
      },
      {
        protocol = "udp"
        ports    = ["8080"]
      }
    ]
  }
  v2ray-ws = {
    name          = "v2ray-ws"
    priority      = 1000
    direction     = "INGRESS"
    target_tags   = ["v2ray-ws"]
    source_ranges = ["0.0.0.0/0"]
    allow = [
      {
        protocol = "tcp"
        ports    = ["9000"]
      },
      {
        protocol = "udp"
        ports    = ["9000"]
      }
    ]
  }
}

# TLS certificates and tunnel secrets (Base64 encoded)
acme_crt                = "<base64(fullchain.crt)>"
acme_key                = "<base64(private.key)>"
cloudflare_tunnel_token = "<cloudflare_tunnel_token>"
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
