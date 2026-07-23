# ==============================================================================
# 1. CORE GCP PROJECT & REGION SETTINGS
# ==============================================================================

variable "gcp_project_id" {
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

variable "default_firewall_rules" {
  description = "Map of GCP firewall rule definitions extracted from the GCP Console"

  type = map(object({
    name               = string                      # Name of the firewall rule
    enforcement_order  = optional(number, 1)         # Enforcement/Execution order
    deployment_scope   = optional(string, "GLOBAL")  # Deployment scope
    priority           = optional(number, 1000)      # Rule priority
    description        = optional(string, null)      # Description of the rule
    direction          = optional(string, "INGRESS") # Direction: INGRESS or EGRESS
    target_tags        = optional(list(string), [])  # Target network tags
    source_ranges      = optional(list(string), [])  # IPv4/IPv6 source ranges
    destination_ranges = optional(list(string), [])  # IPv4/IPv6 destination ranges
    action             = optional(string, "ALLOW")   # Action: ALLOW or DENY
    allow = optional(list(object({                   # Protocol and ports configuration
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
      target_tags        = [] # Applied to all targets
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "all" # All protocols and ports
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
      target_tags        = [] # Applied to all targets
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
      target_tags        = [] # Applied to all targets
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
      target_tags        = [] # Applied to all targets
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
      target_tags        = [] # Applied to all targets
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
      target_tags        = [] # Applied to all instances
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
  description = "Map of custom firewall rule definitions"

  type = map(object({
    name               = optional(string)            # Optional: defaults to map key if omitted
    enforcement_order  = optional(number, 1)         # Execution order
    deployment_scope   = optional(string, "GLOBAL")  # Deployment scope
    priority           = optional(number, 1000)      # Rule priority
    description        = optional(string, null)      # Description
    direction          = optional(string, "INGRESS") # Direction: INGRESS / EGRESS
    target_tags        = optional(list(string), [])  # Target network tags
    source_ranges      = optional(list(string), [])  # IPv4/IPv6 source ranges
    destination_ranges = optional(list(string), [])  # IPv4/IPv6 destination ranges
    action             = optional(string, "ALLOW")   # Action: ALLOW / DENY
    allow = optional(list(object({                   # Dynamic allow protocols and ports
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))

  default = {}
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
  description = "The container image tag or version of the Shadowsocks-rust server application to deploy"
  type        = string
  default     = "1.24.0"
}

variable "services" {
  description = "Map of proxy services and their deployment configurations"
  type = map(object({
    enabled       = bool
    subdomain     = optional(string, "")
    path          = optional(string, "")
    method        = optional(string, "2022-blake3-aes-256-gcm")
    server_port   = optional(number, 9000)
    create_tunnel = optional(bool, false)
  }))

  default = {}

  # Validate that only allowed service keys are defined
  validation {
    condition = length(setsubtract(keys(var.services), [
      "ws", "quic", "grpc", "tls", "cloudflared", "caddy"
    ])) == 0
    error_message = "Invalid service key specified. Allowed options: 'ws', 'quic', 'grpc', 'tls', 'cloudflared', 'caddy'."
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

variable "cloudflare_account_id" {
  type        = string
  description = "Your Cloudflare Account ID"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API Token with Tunnel and DNS permissions"
  sensitive   = true
}

variable "domain" {
  type        = string
  description = "Cloudflare Domain"
}

variable "additional_dns" {
  type        = set(string)
  description = "Additional DNS A record for VM"
  default     = []
}