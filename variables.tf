variable "region" {
  type        = string
  description = "region to deploy to"
  default     = "lax"
}

variable "bucket_name" {
  type    = string
  default = "ghost-kohler-cloud-backup"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "retention" {
  type    = string
  default = "720h"
}

variable "bucket_region" {
  type    = string
  default = "us-east-1"
}

variable "app_name" {
  type    = string
  default = "ghost-kohler-cloud"
}

variable "org" {
  type    = string
  default = "personal"
}

variable "volume_size" {
  type    = string
  default = "10"
}

variable "domain_name" {
  type    = string
  default = "ghost.kohler.cloud"
}


