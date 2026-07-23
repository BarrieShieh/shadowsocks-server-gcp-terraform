# 1. Fetch Zone ID for bloody-moon.com
data "cloudflare_zone" "domain" {
  account_id = var.cloudflare_account_id
  name       = "bloody-moon.com"
}

# 2. Generate a random 32-byte Base64 secret for the tunnel
resource "random_id" "tunnel_secret" {
  byte_length = 32
}

# 3. Create Cloudflare Tunnel: ss-v2ray-test
resource "cloudflare_zero_trust_tunnel_cloudflared" "ss_v2ray_test" {
  account_id = var.cloudflare_account_id
  name       = "v2ray-ws-test"
  secret     = random_id.tunnel_secret.b64_std
}

# 4. Configure ingress routing rules for the tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ss_v2ray_test_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.ss_v2ray_test.id

  config {
    ingress_rule {
      hostname = "test.bloody-moon.com"
      path     = "^/ray"
      service  = "http://v2ray-ws:9000"
    }

    # Mandatory catch-all 404 rule required by Cloudflare
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# 5. Create CNAME DNS record pointing to the tunnel
resource "cloudflare_record" "test_dns" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "test"
  content = cloudflare_zero_trust_tunnel_cloudflared.ss_v2ray_test.cname
  type    = "CNAME"
  proxied = true
}

# 6. Output the tunnel token for cloudflared client deployment
output "tunnel_token" {
  value     = cloudflare_zero_trust_tunnel_cloudflared.ss_v2ray_test.tunnel_token
  sensitive = true
}