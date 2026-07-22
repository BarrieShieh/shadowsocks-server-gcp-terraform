# Dynamically generate random passwords for enabled Shadowsocks services (excluding cloudflared)
resource "random_id" "ss_passwords" {
  for_each = {
    for key, service in var.services : key => service
    if service.enabled && key != "cloudflared"
  }

  byte_length = 32
}