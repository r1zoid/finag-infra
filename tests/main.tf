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

resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-2"
  type     = "network-hdd"
  zone     = var.zone
  size     = "20"
  image_id = var.image_id
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.finag-backend.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.finag-backend.network_interface.0.nat_ip_address
}

resource "yandex_compute_instance" "finag-backend" {
  name = "finag-backend"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
    metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    user-data = "${file("metadata.txt")}"
  }
  platform_id = var.platform
#   instance_template {
#     platform_id = var.platform

#     resources {
#       cores  = var.backend_cores
#       memory = var.backend_memory
#     }

#     boot_disk {
#       initialize_params {
#         image_id = var.image_id
#         type     = "network-hdd"
#         size     = 20
#       }
#     }
#   }
}