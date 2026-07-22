# ==============================================================================
# 1. LOCAL VARIABLES
# ==============================================================================
locals {
  # Read local TLS/SSL certificate files into memory for Docker Compose rendering.
  # "path.module" refers to the root directory of this Terraform module.
  acme_crt = base64decode(var.acme_crt)
  acme_key = base64decode(var.acme_key)
  # Collect all TCP ports defined across var.firewall_rules, flatten the lists, and remove duplicates
  aggregated_tcp_ports = distinct(flatten([
    for rule_key, rule_val in var.firewall_rules : rule_val.tcp_ports
  ]))
  services = {
    for key, service in var.services : key => merge(service, {
      password = try(random_id.ss_passwords[key].b64_std, "")
    })
  }
  active_passwords = {
    for key, res in random_id.ss_passwords : key => res.b64_std
  }
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

resource "google_compute_firewall" "lb_health_check" {
  name    = "${var.instance_name}-lb-health-check"
  network = google_compute_network.app_vpc.name

  # Dynamically assign the aggregated TCP ports
  allow {
    protocol = "tcp"
    ports    = local.aggregated_tcp_ports
  }

  # Dynamically assign IPv4 CIDR blocks retrieved from the Google data source
  source_ranges = data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4
  target_tags   = ["lb-health-check"]
}

# Dynamically generate firewall rules based on the var.firewall_rules map.
# Supports both TCP and UDP protocols independently per rule block.
resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules

  name    = "${var.instance_name}-allow-${each.key}"
  network = google_compute_network.app_vpc.name

  # Dynamically generate TCP allow rules only if tcp_ports is not empty
  dynamic "allow" {
    for_each = length(each.value.tcp_ports) > 0 ? [1] : []
    content {
      protocol = "tcp"
      ports    = each.value.tcp_ports
    }
  }

  # Dynamically generate UDP allow rules only if udp_ports is not empty
  dynamic "allow" {
    for_each = length(each.value.udp_ports) > 0 ? [1] : []
    content {
      protocol = "udp"
      ports    = each.value.udp_ports
    }
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = each.value.target_tags
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
  tags = distinct(concat(
    tolist(google_compute_firewall.lb_health_check.target_tags),
    flatten([for rule in var.firewall_rules : rule.target_tags])
  ))

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