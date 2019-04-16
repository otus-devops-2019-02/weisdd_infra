//output "app_external_ip" {
//  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.assigned_nat_ip}"
//}

//output "app_external_ip2" {
//  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.nat_ip}"
//}
//
//output "db_external_ip2" {
//  value = "${google_compute_instance.db.*.network_interface.0.access_config.0.nat_ip}"
//}

//
//output "Global Forwarding Rule IP" {
//  value = "${google_compute_global_forwarding_rule.fr-reddit-app.ip_address}"
//}

output "app_external_ip2" {
  value = "${module.app.app_external_ip2}"
}

output "db_external_ip2" {
  value = "${module.db.db_external_ip2}"
}

output "db_internal_ip" {
  value = "${module.db.db_internal_ip}"
}
