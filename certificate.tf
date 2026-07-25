# Generate private key for the ACME account
resource "tls_private_key" "acme_account_key" {
  count     = var.enable_cloudflare ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register ACME account
resource "acme_registration" "reg" {
  count           = var.enable_cloudflare ? 1 : 0
  account_key_pem = tls_private_key.acme_account_key[0].private_key_pem
  email_address   = var.email_address
}

# Request wildcard certificate via Cloudflare DNS-01 challenge
resource "acme_certificate" "cert" {
  count                     = var.enable_cloudflare ? 1 : 0
  account_key_pem           = acme_registration.reg[0].account_key_pem
  common_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  # Disable local DNS propagation pre-check
  disable_complete_propagation = var.acme_disable_complete_propagation
  dns_challenge {
    provider = "cloudflare"

    config = {
      CF_DNS_API_TOKEN = var.cloudflare_api_token
    }
  }
}

# Export generated certificates to local files
resource "local_file" "certificate_pem" {
  count    = var.enable_cloudflare ? 1 : 0
  content  = acme_certificate.cert[0].certificate_pem
  filename = "${path.module}/certs/certificate.crt"
}

resource "local_file" "private_key_pem" {
  count    = var.enable_cloudflare ? 1 : 0
  content  = acme_certificate.cert[0].private_key_pem
  filename = "${path.module}/certs/private.key"
}

resource "local_file" "issuer_pem" {
  count    = var.enable_cloudflare ? 1 : 0
  content  = acme_certificate.cert[0].issuer_pem
  filename = "${path.module}/certs/chain.crt"
}

resource "local_file" "fullchain_pem" {
  count    = var.enable_cloudflare ? 1 : 0
  content  = "${acme_certificate.cert[0].certificate_pem}${acme_certificate.cert[0].issuer_pem}"
  filename = "${path.module}/certs/fullchain.crt"
}