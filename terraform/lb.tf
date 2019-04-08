resource "google_compute_instance_group" "ig-reddit-app" {
  name        = "ig-reddit-app"
  description = "Reddit app instance group"

  instances = [
    //    "${google_compute_instance.app.self_link}",
    "${google_compute_instance.app.*.self_link}",
  ]

  named_port {
    name = "http"
    port = "9292"
  }

  zone = "${var.zone}"
}

resource "google_compute_http_health_check" "reddit-http-basic-check" {
  name         = "reddit-http-basic-check"
  request_path = "/"
  port         = 9292
}

resource "google_compute_backend_service" "bs-reddit-app" {
  name        = "bs-reddit-app"
  description = "Backend service for reddit-app"
  port_name   = "http"
  protocol    = "HTTP"
  enable_cdn  = false

  backend {
    group           = "${google_compute_instance_group.ig-reddit-app.self_link}"
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  health_checks = ["${google_compute_http_health_check.reddit-http-basic-check.self_link}"]
}

resource "google_compute_url_map" "urlmap-reddit-app" {
  name        = "urlmap-reddit-app"
  description = "URL-map to redirect traffic to the backend service"

  default_service = "${google_compute_backend_service.bs-reddit-app.self_link}"
}

resource "google_compute_target_http_proxy" "http-lb-proxy-reddit-app" {
  name        = "http-lb-proxy-reddit-app"
  description = "Target HTTP proxy"
  url_map     = "${google_compute_url_map.urlmap-reddit-app.self_link}"
}

resource "google_compute_global_forwarding_rule" "fr-reddit-app" {
  name        = "website-forwarding-rule"
  description = "Forwarding rule"
  target      = "${google_compute_target_http_proxy.http-lb-proxy-reddit-app.self_link}"
  port_range  = "80"
}
