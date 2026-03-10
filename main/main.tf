terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.190"
    }
  }
}

provider "yandex" {
  zone = var.zone
}

locals {
  subnet_zone_cidrs = merge(
    { (var.zone) = var.primary_subnet_cidr },
    var.additional_subnet_cidrs,
  )

  all_zones = sort(keys(local.subnet_zone_cidrs))

  backend_zone             = var.zone
  database_zones           = var.environment == "prod" ? local.all_zones : [var.zone]
  kafka_zones              = var.environment == "prod" ? local.all_zones : [var.zone]
  deployment_environment   = var.environment == "prod" ? "PRODUCTION" : "PRESTABLE"
  kafka_replication_factor = min(3, var.kafka_broker_count)
}

check "backend_scale_bounds" {
  assert {
    condition     = var.backend_max_size >= var.backend_min_size
    error_message = "backend_max_size must be greater than or equal to backend_min_size."
  }
}

check "kafka_prod_brokers" {
  assert {
    condition     = var.environment != "prod" || var.kafka_broker_count >= 3
    error_message = "For prod environment, kafka_broker_count must be at least 3."
  }
}

check "prod_multi_zone_subnets" {
  assert {
    condition     = var.environment != "prod" || length(local.subnet_zone_cidrs) >= 3
    error_message = "Prod requires at least three configured subnets/zones for HA stateful services."
  }
}

resource "yandex_vpc_network" "main" {
  name = "finag-${var.environment}-network"
}

resource "yandex_vpc_subnet" "main" {
  for_each = local.subnet_zone_cidrs

  name           = "finag-${var.environment}-subnet-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [each.value]
}

resource "yandex_compute_instance_group" "backend" {
  name               = "finag-${var.environment}-backend"
  service_account_id = var.service_account_id

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }

  instance_template {
    platform_id = var.platform

    resources {
      cores  = var.backend_cores
      memory = var.backend_memory
    }

    boot_disk {
      initialize_params {
        image_id = var.image_id
        type     = "network-hdd"
        size     = 20
      }
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.main[local.backend_zone].id]
      nat        = false
    }
  }

  scale_policy {
    auto_scale {
      initial_size           = var.backend_min_size
      measurement_duration   = var.backend_measurement_duration
      min_zone_size          = var.backend_min_size
      max_size               = var.backend_max_size
      cpu_utilization_target = var.backend_cpu_target
    }
  }

  allocation_policy {
    zones = [local.backend_zone]
  }

  application_load_balancer {
    target_group_name = "finag-${var.environment}-backend-tg"
  }
}

resource "yandex_alb_http_router" "router" {
  name = "finag-${var.environment}-router"
}

resource "yandex_alb_backend_group" "backend_group" {
  name = "finag-${var.environment}-backend-group"

  http_backend {
    name             = "backend"
    port             = var.backend_port
    target_group_ids = [yandex_compute_instance_group.backend.application_load_balancer[0].target_group_id]
  }
}

resource "yandex_alb_virtual_host" "vhost" {
  name           = "finag-${var.environment}-host"
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

resource "yandex_alb_load_balancer" "lb" {
  name       = "finag-${var.environment}-alb"
  network_id = yandex_vpc_network.main.id

  allocation_policy {
    dynamic "location" {
      for_each = yandex_vpc_subnet.main

      content {
        zone_id   = location.key
        subnet_id = location.value.id
      }
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

resource "yandex_api_gateway" "gateway" {
  name = "finag-${var.environment}-gateway"

  spec = <<EOF_SPEC
openapi: 3.0.0
info:
  title: finance-api
  version: 1.0.0
paths:
  /{proxy+}:
    x-yc-apigateway-any-method:
      parameters:
        - name: proxy
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: http
        url: http://${yandex_alb_load_balancer.lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}/{proxy}
EOF_SPEC
}

resource "yandex_mdb_postgresql_cluster" "pg" {
  name                = "finag-${var.environment}-pg"
  environment         = local.deployment_environment
  network_id          = yandex_vpc_network.main.id
  deletion_protection = var.environment == "prod"

  config {
    resources {
      resource_preset_id = var.pg_resource_preset
      disk_type_id       = "network-ssd"
      disk_size          = var.pg_disk_size
    }
    version = 15
  }

  dynamic "host" {
    for_each = toset(local.database_zones)

    content {
      zone      = host.value
      subnet_id = yandex_vpc_subnet.main[host.value].id
    }
  }
}

resource "yandex_mdb_kafka_cluster" "finag_kafka" {
  name                = "finag-${var.environment}-kafka"
  environment         = local.deployment_environment
  network_id          = yandex_vpc_network.main.id
  deletion_protection = var.environment == "prod"

  config {
    version          = "3"
    brokers_count    = var.kafka_broker_count
    zones            = local.kafka_zones
    assign_public_ip = false
    schema_registry  = false

    rest_api {
      enabled = false
    }

    kafka_ui {
      enabled = false
    }

    kafka {
      resources {
        resource_preset_id = "s2.micro"
        disk_type_id       = "network-ssd"
        disk_size          = var.kafka_disk_size
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
        default_replication_factor      = local.kafka_replication_factor
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
    password = var.kafka_producer_password

    permission {
      topic_name  = "input"
      role        = "ACCESS_ROLE_PRODUCER"
      allow_hosts = var.kafka_allow_hosts
    }
  }

  user {
    name     = "worker"
    password = var.kafka_worker_password

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
