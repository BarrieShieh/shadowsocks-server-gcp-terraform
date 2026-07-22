# ==============================================================================
# 1. LOCAL VARIABLES
# ==============================================================================
locals {
  # Read local TLS/SSL certificate files into memory for Docker Compose rendering.
  # "path.module" refers to the root directory of this Terraform module.
  acme_crt = base64decode(var.acme_crt)
  acme_key = base64decode(var.acme_key)
  services = {
    for key, service in var.services : key => merge(service, {
      password = try(random_id.ss_passwords[key].b64_std, "")
    })
  }
  active_passwords = {
    for key, res in random_id.ss_passwords : key => res.b64_std
  }
  # Merge dynamic rules with custom firewall rules from variable inputs
  firewall_rules = merge(
    var.default_firewall_rules,
    var.firewall_rules
  )
}

# ==============================================================================
# 2. NETWORKING RESOURCES (VPC & FIREWALL)
# ==============================================================================

# Create a dedicated Virtual Private Cloud (VPC) network to isolate application traffic
resource "google_compute_network" "app_vpc" {
  name                    = "${var.instance_name}-vpc"
  auto_create_subnetworks = var.auto_create_subnetworks
}

# Query official Google Cloud IP blocks for load balancer health probes
data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

# Dynamically generate firewall rules based on the var.firewall_rules map.
# Supports both TCP and UDP protocols independently per rule block.
resource "google_compute_firewall" "rules" {
  for_each = local.firewall_rules

  # Name of the firewall rule
  # Note: You can use `each.value.name` directly or prefix it with `${var.instance_name}-${each.value.name}`
  name    = "${var.instance_name}-${each.value.name}"
  network = google_compute_network.app_vpc.name

  # Rule Priority (1 - 65535)
  priority = each.value.priority

  # Description of the firewall rule
  description = each.value.description

  # Direction of traffic: INGRESS or EGRESS
  direction = each.value.direction

  # Source IP ranges (Applicable for INGRESS rules)
  source_ranges = each.value.direction == "INGRESS" && length(each.value.source_ranges) > 0 ? each.value.source_ranges : null

  # Destination IP ranges (Applicable for EGRESS rules)
  destination_ranges = each.value.direction == "EGRESS" && length(each.value.destination_ranges) > 0 ? each.value.destination_ranges : null

  # Target network tags (Applies rule only to instances with matching tags)
  target_tags = length(each.value.target_tags) > 0 ? each.value.target_tags : null

  # Dynamically generate ALLOW protocol and port blocks
  dynamic "allow" {
    for_each = each.value.action == "ALLOW" ? each.value.allow : []
    content {
      protocol = allow.value.protocol
      ports    = length(allow.value.ports) > 0 ? allow.value.ports : null
    }
  }

  # Dynamically generate DENY protocol and port blocks if action is set to DENY
  dynamic "deny" {
    for_each = each.value.action == "DENY" ? each.value.allow : []
    content {
      protocol = deny.value.protocol
      ports    = length(deny.value.ports) > 0 ? deny.value.ports : null
    }
  }
}

# Reserve a static external IP address to ensure persistent public reachability
resource "google_compute_address" "vm_static_ip" {
  name         = "${var.instance_name}-static-ip"
  region       = var.region
  network_tier = var.network_tier
}

# ==============================================================================
# 3. COMPUTE ENGINE INSTANCE
# ==============================================================================
# Track rendered docker-compose content to trigger VM replacement on change
resource "terraform_data" "compose_file" {
  input = templatefile("${path.module}/docker-compose.yml.tftpl", {
    services                = local.services
    ss_version              = var.ss_version
    cloudflare_tunnel_token = var.cloudflare_tunnel_token
    acme_crt                = local.acme_crt
    acme_key                = local.acme_key
  })
}

resource "google_compute_instance" "app_vm" {
  name                      = var.instance_name
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  # Protect the instance from accidental deletion
  deletion_protection = var.enable_deletion_protection

  # Dynamically read target_tags directly from the health check firewall resource
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
    # Reference the output of terraform_data resource
    "compose-file-content" = terraform_data.compose_file.output
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # 1. Install prerequisites for Docker installation on Debian
    apt-get update
    apt-get install -y ca-certificates curl gnupg

    # 2. Add Docker's official GPG key for Debian
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 3. Set up Docker repository pointing specifically to Debian
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 4. Install Docker Engine, CLI, and Compose plugin
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # 5. Retrieve compose file and start containers
    mkdir -p /opt/app
    cd /opt/app

    curl -f -H "Metadata-Flavor: Google" \
      http://metadata.google.internal/computeMetadata/v1/instance/attributes/compose-file-content \
      > docker-compose.yml

    docker compose up -d
  EOF
  # Force replacement (recreation) of the VM whenever metadata/compose content changes
  lifecycle {
    replace_triggered_by = [
      terraform_data.compose_file
    ]
  }
}

# ==============================================================================
# 4. LOCAL SECRETS OUTPUT
# ==============================================================================

# Export generated random passwords to a local JSON file for administration purposes.
# Permissions are restricted to '0600' (read/write for owner only) for security.
resource "local_sensitive_file" "passwords_json" {
  # Only create the file if there is at least one active password service
  count = length(local.active_passwords) > 0 ? 1 : 0

  filename        = "${path.module}/configs/passwords.json"
  file_permission = "0600"

  content = jsonencode(local.active_passwords)
}