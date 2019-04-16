resource "google_storage_bucket" "terraform_state_stage" {
  name     = "terraform-state-stage-31337"
  location = "${var.location}"

  versioning {
    enabled = true
  }

  lifecycle {
    //    prevent_destroy = true
    prevent_destroy = false
  }

  //  force_destroy = false
  force_destroy = true
}

//terraform {
//  backend "gcs" {
//    bucket  = "terraform-state-stage-31337"
//    prefix  = "terraform/state/stage"
//  }
//}

