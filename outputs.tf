# ==============================================================================
# 5. OUTPUT DEFINITIONS
# ==============================================================================

# Map of generated passwords for active proxy services
output "service_passwords" {
  description = "Map of generated base64 passwords for active proxy services, keyed by service name."
  sensitive   = true
  value       = local.active_passwords
}

# Public IP address assigned to the Compute Engine VM
output "vm_external_ip" {
  description = "Static external IP address assigned to the application virtual machine."
  value       = google_compute_instance.app_vm.network_interface[0].access_config[0].nat_ip
}

# Map of Cloudflare Zero Trust Tunnel authentication tokens
output "cloudflare_tunnel_tokens" {
  description = "Map of Cloudflare Zero Trust tunnel authentication tokens, keyed by service."
  sensitive   = true
  value       = var.enable_cloudflare ? { for k, v in cloudflare_zero_trust_tunnel_cloudflared.tunnel : k => v.tunnel_token } : {}
}

# Full TLS certificate chain combining server and issuer PEMs
output "fullchain_pem" {
  description = "Full-chain TLS certificate PEM containing both the server and intermediate issuer certificates."
  sensitive   = true
  value       = var.enable_cloudflare ? "${acme_certificate.cert[0].certificate_pem}${acme_certificate.cert[0].issuer_pem}" : null
}

# Map of SIP002 compliant Shadowsocks connection URIs with optional v2ray-plugin query parameters
output "shadowsocks_uris" {
  description = "Map of SIP002 compliant Shadowsocks URIs for active services, keyed by service name."
  sensitive   = true
  value = local.shadowsocks_uris
}