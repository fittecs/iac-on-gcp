
module "k8s-common" {
  source             = "../../modules/k8s/common"
  service            = "${local.service}"
  env                = "${local.env}"
  cluster_name       = "sample-cluster"
  location           = "asia-northeast1-a"
  network            = "default"
  primary_node_count = "3"
  machine_type       = "n1-standard-1"
  min_master_version = "1.15.7-gke.23"
  node_version       = "1.15.7-gke.23"
}
