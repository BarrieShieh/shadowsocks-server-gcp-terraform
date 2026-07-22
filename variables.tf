# ==============================================================================
# 1. CORE GCP PROJECT & REGION SETTINGS
# ==============================================================================

variable "project_id" {
  description = "The GCP Project ID where resources will be deployed"
  type        = string
  # Mandatory input without default value to prevent accidental deployments
}

variable "region" {
  description = "The GCP region where resources will be hosted"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "The specific GCP zone within the region for resource deployment"
  type        = string
  default     = "us-west1-c"
}

# ==============================================================================
# 2. NETWORKING & FIREWALL CONFIGURATIONS
# ==============================================================================

variable "network_tier" {
  description = "Google Cloud network routing tier. Valid values are 'PREMIUM' or 'STANDARD'"
  type        = string
  default     = "STANDARD"
}

variable "auto_create_subnetworks" {
  description = "When set to true, the VPC network will automatically create subnets in each GCP region"
  type        = bool
  default     = true
}

variable "allowed_source_ranges" {
  description = "List of CIDR blocks permitted to initiate inbound traffic to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "firewall_rules" {
  description = "Map of firewall rule definitions specifying allowed TCP/UDP ports and target network tags"
  type = map(object({
    tcp_ports   = list(string)
    udp_ports   = list(string)
    target_tags = list(string)
  }))
  default = {
    default = {
      tcp_ports   = ["80", "443"]
      udp_ports   = []
      target_tags = ["http-server", "https-server"]
    }
    custom = {
      tcp_ports   = ["8080", "9000"]
      udp_ports   = ["9000"]
      target_tags = ["custom"]
    }
    ssh = {
      tcp_ports   = ["22"]
      udp_ports   = []
      target_tags = ["ssh"]
    }
  }
}

# ==============================================================================
# 3. COMPUTE ENGINE INSTANCE SETTINGS
# ==============================================================================

variable "instance_name" {
  description = "The hostname and resource name of the Compute Engine VM instance"
  type        = string
  default     = "docker-compose-vm"
}

variable "machine_type" {
  description = "The GCP machine type (CPU and RAM allocation) for the VM instance"
  type        = string
  default     = "e2-micro"
}

variable "enable_deletion_protection" {
  description = "Enable or disable deletion protection to prevent accidental VM termination via Terraform or GCP API"
  type        = bool
  default     = true
}

# ==============================================================================
# 4. BOOT DISK CONFIGURATIONS (DEBIAN 12)
# ==============================================================================

variable "boot_disk_family" {
  description = "The OS image family used to fetch the latest Debian release (e.g., debian-12)"
  type        = string
  default     = "debian-12"
}

variable "boot_disk_project" {
  description = "The GCP project hosting official Debian images"
  type        = string
  default     = "debian-cloud"
}

variable "boot_disk_size" {
  description = "The size of the VM boot disk in gigabytes (GB)"
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "The type of persistent disk (e.g., 'pd-standard', 'pd-ssd', 'pd-balanced')"
  type        = string
  default     = "pd-standard"
}

# ==============================================================================
# 5. APPLICATION CONFIGURATIONS (SHADOWSOCKS & V2RAY)
# ==============================================================================

variable "ss_version" {
  description = "The container image tag or version of the Shadowsocks server application to deploy"
  type        = string
  default     = "1.24.0"
}

variable "services" {
  description = "Map of proxy services and their deployment configurations"
  type = map(object({
    enabled     = bool
    host        = optional(string, "")
    method      = optional(string, "2022-blake3-aes-256-gcm")
    server_port = optional(number, 9000)
  }))

  default = {}

  # Validate that only allowed service keys are defined
  validation {
    condition = length(setsubtract(keys(var.services), [
      "v2ray-ws", "v2ray-quic", "v2ray-grpc", "tls", "cloudflared"
    ])) == 0
    error_message = "Invalid service key specified. Allowed options: 'v2ray-ws', 'v2ray-quic', 'v2ray-grpc', 'tls', 'cloudflared'."
  }
}

# ==============================================================================
# 6. SENSITIVE CREDENTIALS & SECRETS
# ==============================================================================
variable "acme_crt" {
  description = "Base64 encoded SSL certificate (fullchain.crt)"
  type        = string
  sensitive   = true
}

variable "acme_key" {
  description = "Base64 encoded SSL private key (private.key)"
  type        = string
  sensitive   = true
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel authentication token used to establish secure edge connections"
  type        = string
  sensitive   = true # Prevents the token from being printed in Terraform logs and console output
}