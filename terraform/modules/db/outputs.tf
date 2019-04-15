output "db_external_ip2" {
  value = "${google_compute_instance.db.*.network_interface.0.access_config.0.nat_ip}"
}
