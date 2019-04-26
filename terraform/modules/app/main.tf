resource "google_compute_instance" "app" {
  count        = "${var.number_of_instances}"
  name         = "reddit-app-${count.index}"
  machine_type = "g1-small"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      # Здесь можно передать либо имя семейства, либо полное имя
      image = "${var.app_disk_image}"
    }
  }

  metadata {
    # путь до публичного ключа
    # file считывает файл и вставляет в конфигурационный файл
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  tags = ["reddit-app", "http-server"]

  labels {
    ansible_group = "app"
    env           = "${var.label_env}"
  }

  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа в Интернет
    access_config {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }

  # Параметры подключения провижионеров
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  //  provisioner "file" {
  //    source      = "${path.module}/files/set_env.sh"
  //    destination = "/tmp/set_env.sh"
  //  }
  //
  //  provisioner "remote-exec" {
  //    inline = [
  //      "/bin/chmod +x /tmp/set_env.sh",
  //      "/tmp/set_env.sh ${var.database_url}",
  //    ]
  //  }
  //
  //  provisioner "file" {
  //    source      = "${path.module}/files/puma.service"
  //    destination = "/tmp/puma.service"
  //  }
  //
  //  provisioner "remote-exec" {
  //    script = "${path.module}/files/deploy.sh"
  //  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"

  # Название сети, в которой действует правило
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["reddit-app"]
}

resource "google_compute_address" "app_ip" {
  name   = "reddit-app-ip"
  region = "${var.region}"
}
