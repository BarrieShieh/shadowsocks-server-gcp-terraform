# ==============================================================================
# 0. PROVIDER CONFIGURATIONS
# ==============================================================================

# Google Cloud Platform provider for managing VPC, firewall, and Compute Engine resources
provider "google" {
  project = var.gcp_project_id
  region  = var.region
  zone    = var.zone
}

# Cloudflare provider for managing Zero Trust tunnels and DNS records
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ACME provider for automated TLS certificate requesting and renewal
provider "acme" {
  server_url = var.acme_server_url
}