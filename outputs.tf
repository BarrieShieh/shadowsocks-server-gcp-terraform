output "shadowsocks_passwords" {
  description = "自动生成的 Shadowsocks 密码列表"
  sensitive   = true # 必须标记为 sensitive，否则 apply 时会报错
  value = {
    v2ray      = random_id.ss_v2ray.b64_std
    v2ray_quic = random_id.ss_v2ray_quic.b64_std
    v2ray_grpc = random_id.ss_v2ray_grpc.b64_std
    http       = random_id.ss_http.b64_std
  }
}

output "vm_external_ip" {
  description = "虚拟机的公网 IP 地址"
  value       = google_compute_instance.app_vm.network_interface[0].access_config[0].nat_ip
}
