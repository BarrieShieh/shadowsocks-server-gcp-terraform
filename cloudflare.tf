locals {
  # Filter active services where enabled is true AND key is NOT 'cloudflared' or 'caddy'
  tunnel_services = {
    for k, v in var.services : k => v if v.enabled && v.create_tunnel && !contains(["cloudflared", "caddy"], k)
  }
}

# Fetch Cloudflare zone data only when there is at least one active service
data "cloudflare_zone" "domain" {
  count      = length(local.tunnel_services) > 0 ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = var.domain
}

# Create a Cloudflare Zero Trust Tunnel for each active service key
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  for_each   = local.tunnel_services
  account_id = var.cloudflare_account_id
  name       = each.key
  secret     = random_id.tunnel_secret[each.key].b64_std
}

# Configure ingress rules for each active service tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  for_each   = local.tunnel_services
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel[each.key].id

  config {
    ingress_rule {
      hostname = "${each.value.subdomain}.${var.domain}"
      path     = each.value.path != "" ? "^${each.value.path}" : null
      service  = "http://${each.key}:${each.value.server_port}"
    }

    # Mandatory catch-all 404 rule required by Cloudflare
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Create CNAME DNS records pointing to each tunnel endpoint
resource "cloudflare_record" "dns" {
  for_each = local.tunnel_services
  zone_id  = data.cloudflare_zone.domain[0].id
  name     = each.value.subdomain
  content  = cloudflare_zero_trust_tunnel_cloudflared.tunnel[each.key].cname
  type     = "CNAME"
  proxied  = true
}

resource "cloudflare_record" "additional_dns" {
  for_each = var.additional_dns
  zone_id  = data.cloudflare_zone.domain[0].id
  name     = each.key
  content  = google_compute_instance.app_vm.network_interface[0].access_config[0].nat_ip
  type     = "A"
  ttl      = 1
  proxied  = true
}
