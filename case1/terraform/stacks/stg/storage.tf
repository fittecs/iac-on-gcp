
module "storage-common" {
  source  = "../../modules/storage/common"
  service = "${local.service}"
  env     = "${local.env}"
}
