# ==============================================================================
# TERRAFORM SETTINGS & REQUIRED PROVIDERS
# ==============================================================================

terraform {
  # Enforce minimum required Terraform CLI version
  required_version = ">= 1.3.0"

  # Declare required provider plugins with source registries and version constraints
  required_providers {
    # Google Cloud Platform provider for managing cloud resources
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    # Random provider for generating cryptographically secure secrets
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    # Local provider for writing sensitive outputs to local files
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }

    # Cloudflare provider for Zero Trust access and network configuration
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }

    # ACME provider for automated SSL/TLS certificate management
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.18"
    }

    # TLS provider for local key generation and PKI management
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}