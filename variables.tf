variable "zone" {
  default = "ru-central1-d"
}

variable "platform" {
  default = "standard-v2"
}

variable "service_account_id" {
  type = string
}

variable "image_id" {
  type = string
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

# Instance group
variable "backend_min_size" { type = number }
variable "backend_max_size" { type = number }
variable "backend_cpu_target" { type = number }

variable "backend_cores" { type = number }
variable "backend_memory" { type = number }

# Postgres

variable "pg_disk_size" { type = number }
variable "pg_resource_preset" {
    type = string
}

#Kafka
variable "kafka_broker_count" {
    type = number 
    description = "Number of Kafka brokers"
}

variable "kafka_disk_size" { 
    type = number
    description = "CPU cores per Kafka broker"
}

