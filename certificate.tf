# Generate private key for the ACME account
resource "tls_private_key" "acme_account_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register ACME account
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.acme_account_key.private_key_pem
  email_address   = var.email_address
}

# Request wildcard certificate via Cloudflare DNS-01 challenge
resource "acme_certificate" "cert" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]

  dns_challenge {
    provider = "cloudflare"

    config = {
      CF_DNS_API_TOKEN = var.cloudflare_api_token
    }
  }
}

# Export generated certificates to local files
resource "local_file" "certificate_pem" {
  content  = acme_certificate.cert.certificate_pem
  filename = "${path.module}/certs/certificate.crt"
}

resource "local_file" "private_key_pem" {
  content  = acme_certificate.cert.private_key_pem
  filename = "${path.module}/certs/private.key"
}

resource "local_file" "issuer_pem" {
  content  = acme_certificate.cert.issuer_pem
  filename = "${path.module}/certs/chain.crt"
}

resource "local_file" "fullchain_pem" {
  content  = "${acme_certificate.cert.certificate_pem}${acme_certificate.cert.issuer_pem}"
  filename = "${path.module}/certs/fullchain.crt"
}

