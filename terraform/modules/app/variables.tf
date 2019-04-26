variable public_key_path {
  description = "Path to the public key used to connect to instance"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh provisioners"
}

variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable "number_of_instances" {
  description = "Number of reddit-app instances (count)"
}

variable "region" {
  description = "Region"
  default     = "europe-west-1"
}

variable "database_url" {
  description = "database_url for reddit app"
  default     = "127.0.0.1:27017"
}

variable "label_env" {
  description = "GCP label 'env' associating an instance with an environment in which it's being run (e.g. stage, prod)"
  default     = "stage"
}
