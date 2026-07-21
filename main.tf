# ==============================================================================
# 1. LOCAL VARIABLES
# ==============================================================================
locals {
  # Read local TLS/SSL certificate files into memory for Docker Compose rendering.
  # "path.module" refers to the root directory of this Terraform module.
  acme_key = file("${path.module}/keys/private.key")
  acme_crt = file("${path.module}/keys/fullchain.crt")
}

# ==============================================================================
# 2. NETWORKING RESOURCES (VPC & FIREWALL)
# ==============================================================================

# Create a dedicated Virtual Private Cloud (VPC) network to isolate application traffic
resource "google_compute_network" "app_vpc" {
  name                    = "${var.instance_name}-vpc"
  auto_create_subnetworks = var.auto_create_subnetworks
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
# DATA SOURCES
# ==============================================================================

# Dynamically fetch the latest patched Debian 12 image from official Google Cloud mirrors
data "google_compute_image" "debian_latest" {
  family  = var.boot_disk_family
  project = var.boot_disk_project
}

# ==============================================================================
# 3. COMPUTE ENGINE INSTANCE
# ==============================================================================

resource "google_compute_instance" "app_vm" {
  name                      = var.instance_name
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true

  tags = distinct(flatten([
    for rule in var.firewall_rules : rule.target_tags
  ]))

  boot_disk {
    initialize_params {
      # Reference the dynamic Debian image link
      image = data.google_compute_image.debian_latest.self_link
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
    "compose-file-content" = templatefile("${path.module}/docker-compose.yml.tftpl", {
      ss_version             = var.ss_version
      ss_encrypt_method      = var.ss_encrypt_method
      ss_v2ray_password      = random_id.ss_v2ray.b64_std
      ss_v2ray_quic_password = random_id.ss_v2ray_quic.b64_std
      ss_v2ray_quic_host     = var.ss_v2ray_quic_host
      ss_v2ray_grpc_password = random_id.ss_v2ray_grpc.b64_std
      ss_v2ray_grpc_host     = var.ss_v2ray_grpc_host
      ss_http_password       = random_id.ss_http.b64_std
      tunnel_token           = var.tunnel_token
      acme_crt               = local.acme_crt
      acme_key               = local.acme_key
    })
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

  # Safeguard to prevent unintended VM deletion when GCP releases new Debian sub-patches
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}

# ==============================================================================
# 4. LOCAL SECRETS OUTPUT
# ==============================================================================

# Export generated random passwords to a local JSON file for administration purposes.
# Permissions are restricted to '0600' (read/write for owner only) for security.
resource "local_sensitive_file" "passwords_json" {
  filename        = "${path.module}/configs/passwords.json"
  file_permission = "0600"

  content = jsonencode({
    v2ray      = random_id.ss_v2ray.b64_std
    v2ray_quic = random_id.ss_v2ray_quic.b64_std
    v2ray_grpc = random_id.ss_v2ray_grpc.b64_std
    http       = random_id.ss_http.b64_std
  })
}