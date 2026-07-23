# Output dynamically generated passwords list
output "shadowsocks_passwords" {
  description = "Dynamically generated list of active Shadowsocks passwords"
  sensitive   = true
  value       = local.active_passwords
}

output "vm_external_ip" {
  description = "External IP address"
  value       = google_compute_instance.app_vm.network_interface[0].access_config[0].nat_ip
}

output "tunnel_token" {
  value     = try(cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].tunnel_token, null)
  sensitive = true
}