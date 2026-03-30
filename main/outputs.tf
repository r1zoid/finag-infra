output "alb_public_ip" {
  description = "Public IPv4 address of Application Load Balancer."
  value       = yandex_alb_load_balancer.lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "alb_base_url" {
  description = "Base URL to access backend through ALB."
  value       = "http://${yandex_alb_load_balancer.lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
}

output "alb_nip_io_host" {
  description = "Convenient wildcard DNS host based on ALB public IP."
  value       = "${yandex_alb_load_balancer.lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}.nip.io"
}

output "backend_database_host" {
  description = "Managed PostgreSQL read-write host for backend."
  value       = "c-${yandex_mdb_postgresql_cluster.pg.id}.rw.mdb.yandexcloud.net"
}

output "backend_database_name" {
  description = "Managed PostgreSQL database name for backend."
  value       = yandex_mdb_postgresql_database.app.name
}
