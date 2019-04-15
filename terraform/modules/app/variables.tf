variable public_key_path {
  description = "Path to the public key used to connect to instance"
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
