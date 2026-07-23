# Dynamically generate random passwords for enabled Shadowsocks services (excluding cloudflared)
resource "random_id" "ss_passwords" {
  for_each = local.active_services

  byte_length = 32
}

# Generate a 32-byte secret for each active service tunnel
resource "random_id" "tunnel_secret" {
  for_each    = local.active_services
  byte_length = 32
}