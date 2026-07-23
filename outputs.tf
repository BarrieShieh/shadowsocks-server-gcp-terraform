# Output dynamically generated passwords list
output "service_passwords" {
  description = "Dynamically generated list of active Shadowsocks passwords"
  sensitive   = true
  value       = local.active_passwords
}

output "vm_external_ip" {
  description = "External IP address"
  value       = google_compute_instance.app_vm.network_interface[0].access_config[0].nat_ip
}

output "cloudflare_tunnel_tokens" {
  description = "Map of Cloudflare tunnel tokens keyed by service"
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared.tunnel : k => v.tunnel_token }
  sensitive   = true
}