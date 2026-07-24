# ==============================================================================
# 1. GCP CORE PROJECT SETTINGS
# ==============================================================================

variable "gcp_project_id" {
  description = "The target GCP Project ID where all resources will be deployed"
  type        = string
}

variable "region" {
  description = "The target GCP region for regional infrastructure resources"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "The specific GCP zone within the region for zonal resource deployment"
  type        = string
  default     = "us-west1-c"
}

# ==============================================================================
# 2. DOMAIN, DNS & ACME SETTINGS
# ==============================================================================

variable "domain" {
  description = "Primary domain name managed via Cloudflare"
  type        = string
}

variable "additional_subdomain" {
  description = "Set of additional subdomains to associate with DNS A records pointing to the VM"
  type        = set(string)
  default     = []
}

variable "email_address" {
  description = "Email address for ACME/Let's Encrypt registration and certificate expiration notices"
  type        = string
}

variable "acme_server_url" {
  description = "The ACME directory URL for SSL/TLS certificate issuing"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

# ==============================================================================
# 3. CLOUDFLARE & EXTERNAL CREDENTIALS
# ==============================================================================

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID associated with the target domain"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token granted with DNS management and Cloudflare Tunnel permissions"
  type        = string
  sensitive   = true
}

# ==============================================================================
# 4. NETWORKING & FIREWALL CONFIGURATIONS
# ==============================================================================

variable "network_tier" {
  description = "GCP network service routing tier. Allowed options: 'PREMIUM' or 'STANDARD'"
  type        = string
  default     = "STANDARD"
}

variable "auto_create_subnetworks" {
  description = "When set to true, automatically provisions default subnets across all GCP regions"
  type        = bool
  default     = true
}

variable "default_firewall_rules" {
  description = "Map of pre-configured GCP firewall rules exported or derived from GCP Console defaults"
  type = map(object({
    name               = string                      # Name of the firewall rule
    enforcement_order  = optional(number, 1)         # Rule execution order
    deployment_scope   = optional(string, "GLOBAL")  # Deployment scope
    priority           = optional(number, 1000)      # Rule evaluation priority
    description        = optional(string, null)      # Rule description
    direction          = optional(string, "INGRESS") # Traffic direction: INGRESS or EGRESS
    target_tags        = optional(list(string), [])  # Applied target network tags
    source_ranges      = optional(list(string), [])  # IPv4/IPv6 source CIDR ranges
    destination_ranges = optional(list(string), [])  # IPv4/IPv6 destination CIDR ranges
    action             = optional(string, "ALLOW")   # Rule action: ALLOW or DENY
    allow = optional(list(object({                   # Allowed protocols and ports configuration
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))

  default = {
    clout-network = {
      name               = "clout-network"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 1000
      description        = "Allow access to all TCP and UDP"
      direction          = "INGRESS"
      target_tags        = []
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
    }
    cloud = {
      name               = "cloud"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 1000
      description        = null
      direction          = "EGRESS"
      target_tags        = []
      source_ranges      = []
      destination_ranges = ["0.0.0.0/0"]
      action             = "ALLOW"
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
    }
    outline = {
      name               = "outline"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 1000
      description        = null
      direction          = "INGRESS"
      target_tags        = ["outline"]
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
    }
    default-allow-icmp = {
      name               = "default-allow-icmp"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 65534
      description        = "Allow ICMP from anywhere"
      direction          = "INGRESS"
      target_tags        = []
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    }
    default-allow-rdp = {
      name               = "default-allow-rdp"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 65534
      description        = "Allow RDP from anywhere"
      direction          = "INGRESS"
      target_tags        = []
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "tcp"
          ports    = ["3389"]
        }
      ]
    }
    default-allow-ssh = {
      name               = "default-allow-ssh"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 65534
      description        = "Allow SSH from anywhere"
      direction          = "INGRESS"
      target_tags        = []
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
    default-allow-health-check = {
      name              = "default-allow-health-check"
      enforcement_order = 1
      deployment_scope  = "GLOBAL"
      priority          = 1000
      description       = "Allow Google Cloud health checks over IPv4"
      direction         = "INGRESS"
      target_tags       = ["lb-health-check"]
      source_ranges = [
        "35.191.0.0/16",
        "130.211.0.0/22",
        "209.85.152.0/22",
        "209.85.204.0/22"
      ]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "tcp"
          ports    = []
        }
      ]
    }
    default-allow-health-check-ipv6 = {
      name              = "default-allow-health-check-ipv6"
      enforcement_order = 1
      deployment_scope  = "GLOBAL"
      priority          = 1000
      description       = "Allow Google Cloud health checks over IPv6"
      direction         = "INGRESS"
      target_tags       = ["lb-health-check"]
      source_ranges = [
        "2600:1901:8001::/48",
        "2600:2d00:1:b029::/64"
      ]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "tcp"
          ports    = []
        }
      ]
    }
    default-allow-internal = {
      name               = "default-allow-internal"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 65534
      description        = "Allow internal traffic on the default network"
      direction          = "INGRESS"
      target_tags        = []
      source_ranges      = ["10.128.0.0/9"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    }
  }
}

variable "firewall_rules" {
  description = "Map of user-defined custom firewall rule configurations"
  type = map(object({
    name               = optional(string)            # Optional: defaults to key name if omitted
    enforcement_order  = optional(number, 1)         # Rule execution order
    deployment_scope   = optional(string, "GLOBAL")  # Deployment scope
    priority           = optional(number, 1000)      # Rule evaluation priority
    description        = optional(string, null)      # Rule description
    direction          = optional(string, "INGRESS") # Direction: INGRESS or EGRESS
    target_tags        = optional(list(string), [])  # Applied target network tags
    source_ranges      = optional(list(string), [])  # IPv4/IPv6 source CIDR ranges
    destination_ranges = optional(list(string), [])  # IPv4/IPv6 destination CIDR ranges
    action             = optional(string, "ALLOW")   # Rule action: ALLOW or DENY
    allow = optional(list(object({                   # Protocol and ports configuration
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))

  default = {}
}

# ==============================================================================
# 5. COMPUTE INSTANCE CONFIGURATIONS
# ==============================================================================

variable "instance_name" {
  description = "Host name and GCP resource ID for the Compute Engine VM instance"
  type        = string
  default     = "docker-compose-vm"
}

variable "machine_type" {
  description = "GCP machine type specifying hardware allocation (vCPU/RAM)"
  type        = string
  default     = "e2-micro"
}

variable "enable_deletion_protection" {
  description = "Prevents accidental destruction of the VM instance via Terraform or API requests"
  type        = bool
  default     = true
}

# ==============================================================================
# 6. BOOT DISK & OPERATING SYSTEM CONFIGURATIONS
# ==============================================================================

variable "boot_disk_family" {
  description = "OS image family used to pull the latest image version (e.g., 'debian-12')"
  type        = string
  default     = "debian-12"
}

variable "boot_disk_project" {
  description = "GCP Project ID hosting the official base operating system image"
  type        = string
  default     = "debian-cloud"
}

variable "boot_disk_size" {
  description = "Allocated boot disk size in Gigabytes (GB)"
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "GCP persistent disk type (e.g., 'pd-standard', 'pd-ssd', 'pd-balanced')"
  type        = string
  default     = "pd-standard"
}

# ==============================================================================
# 7. PROXY SERVICES & APPLICATION CONFIGURATIONS
# ==============================================================================

variable "ss_version" {
  description = "Container image tag or version string for Shadowsocks-rust deployment"
  type        = string
  default     = "1.24.0"
}

variable "services" {
  description = "Map of proxy services and their protocol deployment specifications"
  type = map(object({
    enabled       = bool
    subdomain     = optional(string, "")
    path          = optional(string, "")
    method        = optional(string, "2022-blake3-aes-256-gcm")
    server_port   = optional(number, 9000)
    create_tunnel = optional(bool, false)
  }))

  default = {}

  validation {
    condition = length(setsubtract(keys(var.services), [
      "ws", "quic", "grpc", "tls", "cloudflared", "caddy"
    ])) == 0
    error_message = "Invalid service key detected. Allowed keys are: 'ws', 'quic', 'grpc', 'tls', 'cloudflared', 'caddy'."
  }
}