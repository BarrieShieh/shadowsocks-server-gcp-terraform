# Dynamically generate random passwords for enabled Shadowsocks services (excluding cloudflared)
resource "random_id" "ss_passwords" {
  for_each = {
    for key, service in var.services : key => service
    if service.enabled && key != "cloudflared"
  }

  byte_length = 32
}

resource "random_id" "tunnel_secret" {
  count       = local.enable_tunnel ? 1 : 0
  byte_length = 32
}