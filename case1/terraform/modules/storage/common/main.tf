
variable "service" {}

variable "env" {}

resource "google_storage_bucket" "terraform-backend" {
  name          = "${var.env}-${var.service}-terraform"
  location      = "ASIA"
  storage_class = "MULTI_REGIONAL"
  versioning {
    enabled = true
  }
}
