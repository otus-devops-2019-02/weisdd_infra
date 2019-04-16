resource "google_compute_firewall" "firewall_ssh" {
  name        = "default-allow-ssh"
  description = "Allow SSH from anywhere"
  network     = "default"
  priority    = 65534

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  //  source_ranges = ["0.0.0.0/0"]
  source_ranges = "${var.source_ranges}"
}

resource "google_compute_project_metadata_item" "default" {
  key = "ssh-keys"

  #  value = "${chomp(file(var.public_key_path))}\n${chomp(file(var.public_key_path2))}\n${chomp(file(var.public_key_path3))}"
  value = "appuser:${chomp(file(var.public_key_path))}"
}
