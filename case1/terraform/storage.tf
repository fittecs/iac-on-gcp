
resource "google_storage_bucket" "iac-on-gcp-case1-terraform" {
  name     = "iac-on-gcp-case1-terraform"
  location = "ASIA"
  storage_class = "MULTI_REGIONAL"
  versioning {
    enabled = true
  }
}
