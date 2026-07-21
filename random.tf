# 为 4 个不同的 SS 服务生成符合 2022-blake3-aes-256-gcm 规范的 32 字节 Base64 密钥
resource "random_id" "ss_v2ray" {
  byte_length = 32
}

resource "random_id" "ss_v2ray_quic" {
  byte_length = 32
}

resource "random_id" "ss_v2ray_grpc" {
  byte_length = 32
}

resource "random_id" "ss_http" {
  byte_length = 32
}