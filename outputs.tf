# Output dynamically generated passwords list
output "shadowsocks_passwords" {
  description = "Dynamically generated list of active Shadowsocks passwords"
  sensitive   = true # Must be set to true to avoid errors during terraform apply
  value       = local.active_passwords
}

output "vm_external_ip" {
  description = "External IP address"
  value       = google_compute_instance.app_vm.network_interface[0].access_config[0].nat_ip
}
