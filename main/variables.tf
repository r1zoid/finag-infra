variable "zone" {
  description = "Primary availability zone for provider default operations."
  type        = string
  default     = "ru-central1-d"
}

variable "primary_subnet_cidr" {
  description = "CIDR block for the primary zone subnet."
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.primary_subnet_cidr))
    error_message = "primary_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "additional_subnet_cidrs" {
  description = "Additional zone -> CIDR mappings used for multi-zone deployment."
  type        = map(string)
  default = {
    ru-central1-a = "10.10.1.0/24"
    ru-central1-b = "10.10.2.0/24"
  }

  validation {
    condition     = alltrue([for cidr in values(var.additional_subnet_cidrs) : can(cidrnetmask(cidr))])
    error_message = "Every value in additional_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "platform" {
  description = "Compute platform for backend VMs."
  type        = string
  default     = "standard-v2"
}

variable "service_account_id" {
  description = "Service account used by the managed instance group."
  type        = string
}

variable "image_id" {
  description = "Image id used to initialize backend boot disks."
  type        = string
}

variable "environment" {
  description = "Environment name: dev, stage, or prod."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "backend_min_size" {
  description = "Minimum number of backend instances per zone."
  type        = number

  validation {
    condition     = var.backend_min_size >= 1
    error_message = "backend_min_size must be at least 1."
  }
}

variable "backend_max_size" {
  description = "Maximum number of backend instances in the group."
  type        = number

  validation {
    condition     = var.backend_max_size >= 1
    error_message = "backend_max_size must be at least 1."
  }
}

variable "backend_cpu_target" {
  description = "Autoscaling CPU target percentage."
  type        = number

  validation {
    condition     = var.backend_cpu_target >= 1 && var.backend_cpu_target <= 100
    error_message = "backend_cpu_target must be in range 1..100."
  }
}

variable "backend_cores" {
  description = "CPU cores per backend instance."
  type        = number

  validation {
    condition     = var.backend_cores >= 1
    error_message = "backend_cores must be at least 1."
  }
}

variable "backend_memory" {
  description = "RAM (GB) per backend instance."
  type        = number

  validation {
    condition     = var.backend_memory >= 1
    error_message = "backend_memory must be at least 1 GB."
  }
}

variable "backend_measurement_duration" {
  description = "Autoscaling metrics measurement duration in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.backend_measurement_duration >= 30 && var.backend_measurement_duration <= 600
    error_message = "backend_measurement_duration must be between 30 and 600 seconds."
  }
}

variable "backend_port" {
  description = "Backend application port."
  type        = number
  default     = 8080
}

variable "backend_enable_coi_runtime" {
  description = "When true, backend instances run container workload from metadata docker-compose declaration."
  type        = bool
  default     = false
}

variable "backend_image_registry" {
  description = "Yandex Container Registry ID for backend image (for example: crpXXXXXXXXXXXX)."
  type        = string
  default     = ""
}

variable "backend_image_repository" {
  description = "Container repository name for backend image."
  type        = string
  default     = "finag"
}

variable "backend_image_tag" {
  description = "Container image tag for backend rollout."
  type        = string
  default     = "latest"
}

variable "ssh_user" {
  description = "Linux username for SSH metadata key injection."
  type        = string
  default     = "user"
}

variable "ssh_public_key" {
  description = "Public SSH key line (ssh-ed25519/ssh-rsa ...). Provide through TF_VAR_ssh_public_key."
  type        = string
  default     = ""
}

variable "pg_app_database" {
  description = "Application database name in Managed PostgreSQL."
  type        = string
  default     = "aggr"
}

variable "pg_app_username" {
  description = "Application database user in Managed PostgreSQL."
  type        = string
  default     = "finag_app"
}

variable "pg_app_password" {
  description = "Application database password in Managed PostgreSQL. Provide via TF_VAR_pg_app_password."
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_secret_key" {
  description = "Runtime SECRET_KEY passed to backend container."
  type        = string
  default     = "super-secret-key-for-coursework"
  sensitive   = true
}

variable "app_access_token_expire_minutes" {
  description = "Runtime ACCESS_TOKEN_EXPIRE_MINUTES passed to backend container."
  type        = number
  default     = 60

  validation {
    condition     = var.app_access_token_expire_minutes >= 1
    error_message = "app_access_token_expire_minutes must be >= 1."
  }
}

variable "pg_disk_size" {
  description = "PostgreSQL disk size in GB."
  type        = number

  validation {
    condition     = var.pg_disk_size >= 10
    error_message = "pg_disk_size must be at least 10 GB."
  }
}

variable "pg_resource_preset" {
  description = "PostgreSQL resource preset id."
  type        = string
}

variable "kafka_broker_count" {
  description = "Number of Kafka brokers."
  type        = number

  validation {
    condition     = var.kafka_broker_count >= 1
    error_message = "kafka_broker_count must be at least 1."
  }
}

variable "kafka_disk_size" {
  description = "Kafka broker disk size in GB."
  type        = number

  validation {
    condition     = var.kafka_disk_size >= 10
    error_message = "kafka_disk_size must be at least 10 GB."
  }
}

variable "kafka_allow_hosts" {
  description = "Optional list of hosts allowed for producer connections."
  type        = list(string)
  default     = []
}

variable "kafka_producer_password" {
  description = "Password for Kafka producer user. Provide via TF_VAR_kafka_producer_password or secret tfvars file."
  type        = string
  sensitive   = true
}

variable "kafka_worker_password" {
  description = "Password for Kafka worker user. Provide via TF_VAR_kafka_worker_password or secret tfvars file."
  type        = string
  sensitive   = true
}
