# Настройка провайдера

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-d"
}

# 
resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-hdd"
  zone     = "ru-central1-d"
  size     = "20"
  image_id = var.image_id
}

# VPC
resource "yandex_vpc_network" "main" {
  name = "finag-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "finag-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

#Instance group
resource "yandex_compute_instance_group" "backend" {
  name               = "finag-backend"
  service_account_id = var.service_account_id
  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }
  instance_template {
    platform_id = "standard-v2"

    resources {
      cores  = 4
      memory = 8
    }

    boot_disk {
      disk_id = yandex_compute_disk.boot-disk-1.id
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.main.id]
      nat        = false
    }
  }

  scale_policy {
    auto_scale {
      initial_size           = 2
      measurement_duration   = 100000000
      min_zone_size          = 2
      max_size               = 6
      cpu_utilization_target = 70
    }
  }

  allocation_policy {
    zones = [var.zone]
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "lb" {
  name       = "finance-alb"
  network_id = yandex_vpc_network.main.id

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = yandex_vpc_subnet.main.id
    }
  }

  listener {
    name = "http"

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
  }
}

resource "yandex_alb_http_router" "router" {
  name = "finag-router"
}

resource "yandex_alb_backend_group" "backend_group" {
  name = "finag-backend-group"

  http_backend {
    name             = "backend"
    port             = 8080
    target_group_ids = ["${yandex_alb_target_group.group.id}"]
  }
}

resource "yandex_alb_target_group" "group" {
  name = "group"

  target {
    subnet_id  = yandex_vpc_subnet.main.id
    ip_address = "10.10.0.1"
  }

  target {
    subnet_id  = yandex_vpc_subnet.main.id
    ip_address = "10.10.0.2"
  }
}

resource "yandex_alb_virtual_host" "vhost" {
  name           = "finag-host"
  http_router_id = yandex_alb_http_router.router.id

  route {
    name = "default"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend_group.id
      }
    }
  }
}




# API Gateway
resource "yandex_api_gateway" "gateway" {
  name = "finance-gateway"

  spec = <<EOF
openapi: 3.0.0
info:
  title: finance-api
  version: 1.0.0
paths:
  /proxy:
    x-yc-apigateway-any-method:
      x-yc-apigateway-integration:
        type: http
        url: http://${yandex_alb_load_balancer.lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}/{proxy}
EOF
}

# Managed Postgres

resource "yandex_mdb_postgresql_cluster" "pg" {
  name        = "finag-pg"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  config {
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 16
    }
    version = 15
  }


  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.main.id
  }
}


# Kafka cluster 

resource "yandex_mdb_kafka_cluster" "finag-kafka" {
  name        = "finag-kafka"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id
  config {
    version          = "2.8"
    brokers_count    = 1
    zones            = ["ru-central1-d"]
    assign_public_ip = false
    schema_registry  = false
    rest_api {
      enabled = true
    }
    kafka_ui {
      enabled = true
    }
    kafka {
      resources {
        resource_preset_id = "s2.micro"
        disk_type_id       = "network-ssd"
        disk_size          = 32
      }
      kafka_config {
        compression_type                = "COMPRESSION_TYPE_ZSTD"
        log_flush_interval_messages     = 1024
        log_flush_interval_ms           = 1000
        log_flush_scheduler_interval_ms = 1000
        log_retention_bytes             = 1073741824
        log_retention_hours             = 168
        log_retention_minutes           = 10080
        log_retention_ms                = 86400000
        log_segment_bytes               = 134217728
        num_partitions                  = 10
        default_replication_factor      = 1
        message_max_bytes               = 1048588
        replica_fetch_max_bytes         = 1048576
        ssl_cipher_suites               = ["TLS_DHE_RSA_WITH_AES_128_CBC_SHA", "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"]
        offsets_retention_minutes       = 10080
        sasl_enabled_mechanisms         = ["SASL_MECHANISM_SCRAM_SHA_256", "SASL_MECHANISM_SCRAM_SHA_512"]
      }
    }
  }

  user {
    name     = "producer-application"
    password = "password"
    permission {
      topic_name  = "input"
      role        = "ACCESS_ROLE_PRODUCER"
      allow_hosts = ["host1.db.yandex.net", "host2.db.yandex.net"]
    }
  }

  user {
    name     = "worker"
    password = "password"
    permission {
      topic_name = "input"
      role       = "ACCESS_ROLE_CONSUMER"
    }
    permission {
      topic_name = "output"
      role       = "ACCESS_ROLE_PRODUCER"
    }
  }
}

// Auxiliary resources
resource "yandex_vpc_network" "foo" {}

resource "yandex_vpc_subnet" "foo" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.foo.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}