variable "zone" {
  description = "Primary availability zone for provider default operations."
  type        = string
  default     = "ru-central1-d"
}

variable "service_account_id" {
  description = "Service account used by the managed instance group."
  type        = string
}

variable "platform" {
  description = "Compute platform for backend VMs."
  type        = string
  default     = "standard-v2"
}

variable "backend_cores" {
    description = "VM Backend Cores"
    type = number
    default = 1
}

variable "backend_memory" {
    description = "VM Backend memory"
    type = number
    default = 2
}

variable "image_id" {
    description = "Backend image id"
    type = string 
    default = "fd86k5lln2u2bvfuk00u"
}