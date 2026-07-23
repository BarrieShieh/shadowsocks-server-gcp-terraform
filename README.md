
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
- **Useful Outputs:** Automatically formats and exports connection URIs (`ss://`) upon successful deployment.

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
Prerequisites
Ensure you have installed and configured the following tools on your local machine:

Terraform (v1.0.0 or higher)

Google Cloud SDK (gcloud)

An active GCP Project with billing enabled.

GCP Authentication
Log in to your Google Cloud account locally via gcloud:

Bash
# Authenticate Application Default Credentials (ADC) for Terraform
gcloud auth application-default login

# Set your default active GCP project
gcloud config set project YOUR_GCP_PROJECT_ID
Quick Start
1. Clone the Repository
Bash
git clone [https://github.com/BarrieShieh/shadowsocks-server-gcp-terraform.git](https://github.com/BarrieShieh/shadowsocks-server-gcp-terraform.git)
cd shadowsocks-server-gcp-terraform
2. Configure Variables
Copy the example variable file to create your own configuration:

Bash
cp terraform.tfvars.example terraform.tfvars
Edit terraform.tfvars with your preferred settings:

Terraform
# Google Cloud Configuration
project_id  = "your-gcp-project-id"
region      = "asia-east1"
zone        = "asia-east1-a"
machine_type= "e2-micro"

# Shadowsocks Service Parameters
ss_port     = 8388
ss_password = "YourStrongSecretPassword"
ss_cipher   = "chacha20-ietf-poly1305"
3. Deploy Infrastructure
Initialize Terraform working directory and plugins:

Bash
terraform init
Review the deployment plan:

Bash
terraform plan
Apply configuration to build resources in GCP:

Bash
terraform apply
When prompted, type yes to confirm the resource creation.

Connecting to Shadowsocks
After deployment completes, Terraform will output your instance's public IP address and a pre-formatted Shadowsocks URI:

Plaintext
Outputs:

public_ip = "123.45.67.89"
ss_port   = 8388
ss_uri    = "ss://YWVzLTI1Ni1nY206WW91clN0cm9uZ1NlY3JldFBhc3N3b3JkQDEyMy40NS42Ny44OTo4Mzg4"
Copy the ss_uri link directly into your Shadowsocks client (iOS, Android, macOS, Windows) to import the server configuration automatically.

Inputs & Outputs
Inputs
Name	Description	Type	Default	Required
project_id	GCP Project ID where resources will be created.	string	n/a	yes
region	Target GCP region for resource allocation.	string	"asia-east1"	no
zone	Target GCP zone for instance placement.	string	"asia-east1-a"	no
machine_type	Compute Engine instance machine type.	string	"e2-micro"	no
ss_port	Listening port for the Shadowsocks server.	number	8388	no
ss_password	Secret password for client authentication.	string	n/a	yes
ss_cipher	Encryption cipher (e.g., chacha20-ietf-poly1305, aes-256-gcm).	string	"chacha20-ietf-poly1305"	no
Outputs
Name	Description
public_ip	External IPv4 address assigned to the server VM.
ss_port	The port on which Shadowsocks is listening.
ss_uri	Encoded ss:// connection string for easy client import.
Cleanup / Teardown
To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

Bash
terraform destroy
Confirm with yes when prompted.

License
This project is licensed under the MIT License - see the LICENSE file for details.

生成这个文件的下载链接

Prerequisites
Ensure you have installed and configured the following tools on your local machine:

Terraform (v1.0.0 or higher)

Google Cloud SDK (gcloud)

An active GCP Project with billing enabled.

GCP Authentication
Log in to your Google Cloud account locally via gcloud:

Bash
# Authenticate Application Default Credentials (ADC) for Terraform
gcloud auth application-default login

# Set your default active GCP project
gcloud config set project YOUR_GCP_PROJECT_ID
Quick Start
1. Clone the Repository
Bash
git clone [https://github.com/BarrieShieh/shadowsocks-server-gcp-terraform.git](https://github.com/BarrieShieh/shadowsocks-server-gcp-terraform.git)
cd shadowsocks-server-gcp-terraform
2. Configure Variables
Copy the example variable file to create your own configuration:

Bash
cp terraform.tfvars.example terraform.tfvars
Edit terraform.tfvars with your preferred settings:

Terraform
# Google Cloud Configuration
project_id  = "your-gcp-project-id"
region      = "asia-east1"
zone        = "asia-east1-a"
machine_type= "e2-micro"

# Shadowsocks Service Parameters
ss_port     = 8388
ss_password = "YourStrongSecretPassword"
ss_cipher   = "chacha20-ietf-poly1305"
3. Deploy Infrastructure
Initialize Terraform working directory and plugins:

Bash
terraform init
Review the deployment plan:

Bash
terraform plan
Apply configuration to build resources in GCP:

Bash
terraform apply
When prompted, type yes to confirm the resource creation.

Connecting to Shadowsocks
After deployment completes, Terraform will output your instance's public IP address and a pre-formatted Shadowsocks URI:

Plaintext
Outputs:

public_ip = "123.45.67.89"
ss_port   = 8388
ss_uri    = "ss://YWVzLTI1Ni1nY206WW91clN0cm9uZ1NlY3JldFBhc3N3b3JkQDEyMy40NS42Ny44OTo4Mzg4"
Copy the ss_uri link directly into your Shadowsocks client (iOS, Android, macOS, Windows) to import the server configuration automatically.

Inputs & Outputs
Inputs
Name	Description	Type	Default	Required
project_id	GCP Project ID where resources will be created.	string	n/a	yes
region	Target GCP region for resource allocation.	string	"asia-east1"	no
zone	Target GCP zone for instance placement.	string	"asia-east1-a"	no
machine_type	Compute Engine instance machine type.	string	"e2-micro"	no
ss_port	Listening port for the Shadowsocks server.	number	8388	no
ss_password	Secret password for client authentication.	string	n/a	yes
ss_cipher	Encryption cipher (e.g., chacha20-ietf-poly1305, aes-256-gcm).	string	"chacha20-ietf-poly1305"	no
Outputs
Name	Description
public_ip	External IPv4 address assigned to the server VM.
ss_port	The port on which Shadowsocks is listening.
ss_uri	Encoded ss:// connection string for easy client import.
Cleanup / Teardown
To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

Bash
terraform destroy
Confirm with yes when prompted.

License
This project is licensed under the MIT License - see the LICENSE file for details.
"""

file_path = "README.md"
with open(file_path, "w", encoding="utf-8") as f:
f.write(readme_content)

print(f"File created successfully: {file_path}")


```text?code_stdout&code_event_index=1
File created successfully: README.md

Your Markdown (README.md) file is ready
MD 图标
README
 MD 
打开

README.md 文件已成功生成，你可以点击上方的文件标签直接下载使用。

将这部分优化追加进readme，更新下载链接

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

Prerequisites
Ensure you have installed and configured the following tools on your local machine:

Terraform (v1.0.0 or higher)

Google Cloud SDK (gcloud)

An active GCP Project with billing enabled.

🚀 Quick Start & CLI Operations
Follow these shell commands to authenticate with Google Cloud, configure project quotas, apply infrastructure changes, and access the deployed instance. All command comments are provided in English as specified.

Shell
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
Connecting to Shadowsocks
After deployment completes, Terraform will output your instance's public IP address and a pre-formatted Shadowsocks URI:

Plaintext
Outputs:

public_ip = "123.45.67.89"
ss_port   = 8388
ss_uri    = "ss://YWVzLTI1Ni1nY206WW91clN0cm9uZ1NlY3JldFBhc3N3b3JkQDEyMy40NS42Ny44OTo4Mzg4"
Copy the ss_uri link directly into your Shadowsocks client (iOS, Android, macOS, Windows) to import the server configuration automatically.

Inputs & Outputs
Inputs
Name	Description	Type	Default	Required
project_id	GCP Project ID where resources will be created.	string	n/a	yes
region	Target GCP region for resource allocation.	string	"asia-east1"	no
zone	Target GCP zone for instance placement.	string	"asia-east1-a"	no
machine_type	Compute Engine instance machine type.	string	"e2-micro"	no
ss_port	Listening port for the Shadowsocks server.	number	8388	no
ss_password	Secret password for client authentication.	string	n/a	yes
ss_cipher	Encryption cipher (e.g., chacha20-ietf-poly1305, aes-256-gcm).	string	"chacha20-ietf-poly1305"	no
Outputs
Name	Description
public_ip	External IPv4 address assigned to the server VM.
ss_port	The port on which Shadowsocks is listening.
ss_uri	Encoded ss:// connection string for easy client import.
Cleanup / Teardown
To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

Bash
terraform destroy
Confirm with yes when prompted.

License
This project is licensed under the MIT License - see the LICENSE file for details.
"""

file_path = "README.md"
with open(file_path, "w", encoding="utf-8") as f:
f.write(updated_readme_content)

print(f"File updated successfully: {file_path}")


```text?code_stdout&code_event_index=1
File updated successfully: README.md

已将优化后的 🚀 Quick Start & CLI Operations 章节整合追加至 README.md 中。

更新后的文件下载链接
[file-tag: code-generated-file-47d85dfa-7ce3-46b5-9c61-2e2142b82ecb]

完整的 README.md 内容
Markdown
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
- **Useful Outputs:** Automatically formats and exports connection URIs (`ss://`) upon successful deployment.

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
Prerequisites
Ensure you have installed and configured the following tools on your local machine:

Terraform (v1.0.0 or higher)

Google Cloud SDK (gcloud)

An active GCP Project with billing enabled.

🚀 Quick Start & CLI Operations
Follow these shell commands to authenticate with Google Cloud, configure project quotas, apply infrastructure changes, and access the deployed instance. All command comments are provided in English as specified.

Shell
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
Connecting to Shadowsocks
After deployment completes, Terraform will output your instance's public IP address and a pre-formatted Shadowsocks URI:

Plaintext
Outputs:

public_ip = "123.45.67.89"
ss_port   = 8388
ss_uri    = "ss://YWVzLTI1Ni1nY206WW91clN0cm9uZ1NlY3JldFBhc3N3b3JkQDEyMy40NS42Ny44OTo4Mzg4"
Copy the ss_uri link directly into your Shadowsocks client (iOS, Android, macOS, Windows) to import the server configuration automatically.

Inputs & Outputs
Inputs
Name	Description	Type	Default	Required
project_id	GCP Project ID where resources will be created.	string	n/a	yes
region	Target GCP region for resource allocation.	string	"asia-east1"	no
zone	Target GCP zone for instance placement.	string	"asia-east1-a"	no
machine_type	Compute Engine instance machine type.	string	"e2-micro"	no
ss_port	Listening port for the Shadowsocks server.	number	8388	no
ss_password	Secret password for client authentication.	string	n/a	yes
ss_cipher	Encryption cipher (e.g., chacha20-ietf-poly1305, aes-256-gcm).	string	"chacha20-ietf-poly1305"	no
Outputs
Name	Description
public_ip	External IPv4 address assigned to the server VM.
ss_port	The port on which Shadowsocks is listening.
ss_uri	Encoded ss:// connection string for easy client import.
Cleanup / Teardown
To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

Bash
terraform destroy
Confirm with yes when prompted.

License
This project is licensed under the MIT License - see the LICENSE file for details.

重新生成这个文件的下载链接

Prerequisites
Ensure you have installed and configured the following tools on your local machine:

Terraform (v1.0.0 or higher)

Google Cloud SDK (gcloud)

An active GCP Project with billing enabled.

🚀 Quick Start & CLI Operations
Follow these shell commands to authenticate with Google Cloud, configure project quotas, apply infrastructure changes, and access the deployed instance. All command comments are provided in English as specified.

Shell
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
Connecting to Shadowsocks
After deployment completes, Terraform will output your instance's public IP address and a pre-formatted Shadowsocks URI:

Plaintext
Outputs:

public_ip = "123.45.67.89"
ss_port   = 8388
ss_uri    = "ss://YWVzLTI1Ni1nY206WW91clN0cm9uZ1NlY3JldFBhc3N3b3JkQDEyMy40NS42Ny44OTo4Mzg4"
Copy the ss_uri link directly into your Shadowsocks client (iOS, Android, macOS, Windows) to import the server configuration automatically.

Inputs & Outputs
Inputs
Name	Description	Type	Default	Required
project_id	GCP Project ID where resources will be created.	string	n/a	yes
region	Target GCP region for resource allocation.	string	"asia-east1"	no
zone	Target GCP zone for instance placement.	string	"asia-east1-a"	no
machine_type	Compute Engine instance machine type.	string	"e2-micro"	no
ss_port	Listening port for the Shadowsocks server.	number	8388	no
ss_password	Secret password for client authentication.	string	n/a	yes
ss_cipher	Encryption cipher (e.g., chacha20-ietf-poly1305, aes-256-gcm).	string	"chacha20-ietf-poly1305"	no
Outputs
Name	Description
public_ip	External IPv4 address assigned to the server VM.
ss_port	The port on which Shadowsocks is listening.
ss_uri	Encoded ss:// connection string for easy client import.
Cleanup / Teardown
To avoid ongoing GCP charges, you can remove all infrastructure managed by this project:

Bash
terraform destroy
Confirm with yes when prompted.

License
This project is licensed under the MIT License - see the LICENSE file for details.
"""

file_path = "README-v2.md"
with open(file_path, "w", encoding="utf-8") as f:
f.write(readme_content)

print(f"File created: {file_path}")


```text?code_stdout&code_event_index=1
File created: README-v2.md

Your Markdown (README.md) file is ready
MD 图标
README-v2
 MD 
打开

已为你重新生成包含最新配置的 README-v2.md 文件，你可以点击上方的文件标签重新下载。




Gemini 是一款 AI 工具，其回答未必正确无误。

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
- **Useful Outputs:** Automatically formats and exports connection URIs (`ss://`) upon successful deployment.

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

## Connecting to Shadowsocks

After deployment completes, Terraform will output your instance's public IP address and a pre-formatted Shadowsocks URI:

```text
Outputs:

public_ip = "123.45.67.89"
ss_port   = 8388
ss_uri    = "ss://YWVzLTI1Ni1nY206WW91clN0cm9uZ1NlY3JldFBhc3N3b3JkQDEyMy40NS42Ny44OTo4Mzg4"
```

Copy the `ss_uri` link directly into your Shadowsocks client (iOS, Android, macOS, Windows) to import the server configuration automatically.

---

## Inputs & Outputs

### Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| `project_id` | GCP Project ID where resources will be created. | `string` | n/a | **yes** |
| `region` | Target GCP region for resource allocation. | `string` | `"asia-east1"` | no |
| `zone` | Target GCP zone for instance placement. | `string` | `"asia-east1-a"` | no |
| `machine_type` | Compute Engine instance machine type. | `string` | `"e2-micro"` | no |
| `ss_port` | Listening port for the Shadowsocks server. | `number` | `8388` | no |
| `ss_password` | Secret password for client authentication. | `string` | n/a | **yes** |
| `ss_cipher` | Encryption cipher (e.g., `chacha20-ietf-poly1305`, `aes-256-gcm`). | `string` | `"chacha20-ietf-poly1305"` | no |

### Outputs

| Name | Description |
| :--- | :--- |
| `public_ip` | External IPv4 address assigned to the server VM. |
| `ss_port` | The port on which Shadowsocks is listening. |
| `ss_uri` | Encoded `ss://` connection string for easy client import. |

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
