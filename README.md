# GCP Shadowsocks Server with Terraform

An automated Infrastructure-as-Code (IaC) project to deploy and manage a secure [Shadowsocks](https://shadowsocks.org/) proxy server on Google Cloud Platform (GCP) using [Terraform](https://www.terraform.io/).

---

## Overview

This repository provides a fully automated setup for running a containerized Shadowsocks server on a GCP Compute Engine instance. It automatically provisions the necessary virtual network, configures ingress/egress firewall rules, boots a Virtual Machine (VM), and initializes the Shadowsocks service upon startup.

## Features

- **Automated Infrastructure:** Zero-touch provisioning and teardown using standard Terraform workflows.
- **Firewall & Security Configuration:** Configures specific GCP Compute Firewall ingress rules for Shadowsocks traffic, SSH access, and ICMP health checks.
- **Dockerized Setup:** Runs the Shadowsocks service via Docker inside the instance for isolation, stability, and easy updates.
- **Flexible Parameters:** Customizable server specs, region/zone selection, proxy listening ports, passwords, and encryption ciphers via Terraform variables.


---

## Repository Structure

```text
.
├── main.tf                  # Primary GCP resource definitions (Compute instance, Firewall rules, Network interfaces)
├── variables.tf             # Input variables declaration and validation rules
├── outputs.tf               # Infrastructure outputs (External IP, Connection URI, Port)
├── terraform.tfvars.example # Example variable configuration template
├── scripts/
│   └── startup.sh           # Cloud-init / Shell startup script for Docker and Shadowsocks startup
└── README.md                # Project documentation
```

---

## Prerequisites

Ensure you have installed and configured the following tools on your local machine:

1. **[Terraform](https://developer.hashicorp.com/terraform/downloads)** (v1.0.0 or higher)
2. **[Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install)**
3. An active **GCP Project** with billing enabled.

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
```

---

## Cleanup / Teardown

To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

```bash
terraform destroy
```

Confirm with `yes` when prompted.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
