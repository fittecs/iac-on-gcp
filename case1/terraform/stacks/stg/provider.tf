
provider "google" {
  version = "~> 2.15"
  project = "${var.project}"
  region  = "asia-northeast1"
}
