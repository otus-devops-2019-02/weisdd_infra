variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region"
  default     = "europe-west-1"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

//variable "public_key_path2" {
//  description = "Path to the public key used for ssh access"
//}
//
//variable "public_key_path3" {
//  description = "Path to the public key used for ssh access"
//}

variable "disk_image" {
  description = "Disk image"
}

variable "app_disk_image" {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable "db_disk_image" {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh provisioners"
}

variable "zone" {
  description = "Zone"
  default     = "europe-west1-b"
}

variable "number_of_instances" {
  description = "Number of reddit-app instances (count)"
}
