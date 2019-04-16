output "app_external_ip2" {
  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.nat_ip}"
}
