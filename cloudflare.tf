locals {
  service_key   = "ws"
  enable_tunnel = contains(keys(var.services), local.service_key)
}

data "cloudflare_zone" "domain" {
  count      = local.enable_tunnel ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = var.domain
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  count      = local.enable_tunnel ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = local.service_key
  secret     = random_id.tunnel_secret[0].b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ss_v2ray_test_config" {
  count      = local.enable_tunnel ? 1 : 0
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].id

  config {
    ingress_rule {
      hostname = "${var.instance_name}-${local.service_key}.${var.domain}"
      path     = "^/${local.service_key}"
      service  = "http://${local.service_key}:${local.services[local.service_key].server_port}"
    }

    # Mandatory catch-all 404 rule required by Cloudflare
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "test_dns" {
  count   = local.enable_tunnel ? 1 : 0
  zone_id = data.cloudflare_zone.domain[0].id
  name    = local.service_key
  content = cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].cname
  type    = "CNAME"
  proxied = true
}

