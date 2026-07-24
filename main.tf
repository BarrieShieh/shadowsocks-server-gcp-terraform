# ==============================================================================
# 1. LOCAL VARIABLES & MAP TRANSFORMATIONS
# ==============================================================================

locals {
  # Concatenate certificate authority and server certificate PEMs for TLS handshakes
  acme_crt = "${acme_certificate.cert.certificate_pem}${acme_certificate.cert.issuer_pem}"
  acme_key = acme_certificate.cert.private_key_pem

  # Merge service configurations with randomly generated passwords
  services = {
    for key, service in var.services : key => merge(service, {
      password = try(random_id.ss_passwords[key].b64_std, "")
    })
  }

  # Filter out non-target proxy services requiring password generation
  active_services = {
    for k, v in var.services : k => v if v.enabled && !contains(["cloudflared", "caddy"], k)
  }

  # Map generated base64 passwords by service key
  active_passwords = {
    for key, res in random_id.ss_passwords : key => res.b64_std
  }

  # Dynamically build ingress firewall rule schemas for active services (TCP + UDP)
  service_firewall_rules = {
    for key, svc in var.services : "svc-${key}" => {
      name               = "allow-${key}"
      enforcement_order  = 1
      deployment_scope   = "GLOBAL"
      priority           = 1000
      description        = "Auto-generated ingress rule for service: ${key}"
      direction          = "INGRESS"
      target_tags        = [key]
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = []
      action             = "ALLOW"
      allow = [
        {
          protocol = "tcp"
          ports    = [tostring(svc.server_port)]
        },
        {
          protocol = "udp"
          ports    = [tostring(svc.server_port)]
        }
      ]
    }
    if svc.enabled
  }

  # Layer firewall rules with precedence: Default < Service-generated < Custom Overrides
  firewall_rules = merge(
    var.default_firewall_rules,
    local.service_firewall_rules,
    var.firewall_rules
  )
}

# ==============================================================================
# 2. NETWORKING & FIREWALL INFRASTRUCTURE
# ==============================================================================

# Dedicated Custom VPC network for workload isolation
resource "google_compute_network" "app_vpc" {
  name                    = "${var.instance_name}-vpc"
  auto_create_subnetworks = var.auto_create_subnetworks
}

# Fetch official Google Cloud health check IP blocks for load balancing
data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

# Dynamic ingress/egress firewall rules derived from merged local.firewall_rules map
resource "google_compute_firewall" "rules" {
  for_each = local.firewall_rules

  name        = "${var.instance_name}-${each.value.name}"
  network     = google_compute_network.app_vpc.name
  priority    = each.value.priority
  description = each.value.description
  direction   = each.value.direction

  # Conditionally apply CIDR ranges based on rule direction
  source_ranges      = each.value.direction == "INGRESS" && length(each.value.source_ranges) > 0 ? each.value.source_ranges : null
  destination_ranges = each.value.direction == "EGRESS" && length(each.value.destination_ranges) > 0 ? each.value.destination_ranges : null

  # Restrict scope to instances tagged with matching network tags
  target_tags = length(each.value.target_tags) > 0 ? each.value.target_tags : null

  # Generate protocol/port allow blocks
  dynamic "allow" {
    for_each = each.value.action == "ALLOW" ? each.value.allow : []
    content {
      protocol = allow.value.protocol
      ports    = length(allow.value.ports) > 0 ? allow.value.ports : null
    }
  }

  # Generate protocol/port deny blocks
  dynamic "deny" {
    for_each = each.value.action == "DENY" ? each.value.allow : []
    content {
      protocol = deny.value.protocol
      ports    = length(deny.value.ports) > 0 ? deny.value.ports : null
    }
  }
}

# Static public IP reservation for persistent DNS mapping
resource "google_compute_address" "vm_static_ip" {
  name         = "${var.instance_name}-static-ip"
  region       = var.region
  network_tier = var.network_tier
}

# ==============================================================================
# 3. COMPUTE ENGINE WORKLOAD
# ==============================================================================

# Track rendered Docker Compose template state to trigger VM re-creation on updates
resource "terraform_data" "compose_file" {
  input = templatefile("${path.module}/docker-compose.yml.tftpl", {
    services                 = local.services
    domain                   = var.domain
    ss_version               = var.ss_version
    cloudflare_tunnel_tokens = { for k, t in cloudflare_zero_trust_tunnel_cloudflared.tunnel : k => t.tunnel_token }
    acme_crt                 = local.acme_crt
    acme_key                 = local.acme_key
  })
}

resource "google_compute_instance" "app_vm" {
  name                      = var.instance_name
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true
  deletion_protection       = var.enable_deletion_protection

  # Aggregate all firewall target tags across configured rules
  tags = distinct(flatten([
    for rule_key, rule in local.firewall_rules : rule.target_tags
  ]))

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_project}/${var.boot_disk_family}"
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = google_compute_network.app_vpc.name
    access_config {
      nat_ip       = google_compute_address.vm_static_ip.address
      network_tier = var.network_tier
    }
  }

  metadata = {
    "compose-file-content" = terraform_data.compose_file.output
  }

  # Automated provisioning script: Installs Docker runtime and initializes services
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # 1. Install system dependencies for Docker APT repository
    apt-get update
    apt-get install -y ca-certificates curl gnupg

    # 2. Add Docker official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 3. Configure stable Docker APT repository for Debian
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 4. Install Docker Engine and Compose plugin
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # 5. Fetch rendered Compose file from Instance Metadata and start containers
    mkdir -p /opt/app
    cd /opt/app

    curl -f -H "Metadata-Flavor: Google" \
      http://metadata.google.internal/computeMetadata/v1/instance/attributes/compose-file-content \
      > docker-compose.yml

    docker compose up -d
  EOF

  # Force replacement of the VM when the rendered compose configuration changes
  lifecycle {
    replace_triggered_by = [
      terraform_data.compose_file
    ]
  }
}

# ==============================================================================
# 4. SECRETS GENERATION & LOCAL EXPORTS
# ==============================================================================

# Export sensitive administrative secrets to a restricted local JSON file (owner read/write only)
resource "local_sensitive_file" "passwords_json" {
  count = length(local.active_passwords) > 0 ? 1 : 0

  filename        = "${path.module}/configs/passwords.json"
  file_permission = "0600"
  content         = jsonencode(local.active_passwords)
}

# Generate cryptographically secure random base64 passwords for active services
resource "random_id" "ss_passwords" {
  for_each = local.active_services

  byte_length = 32
}