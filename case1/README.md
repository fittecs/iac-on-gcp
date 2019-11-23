# iac-on-gcp

## 初期手順

- プロジェクトを手動で作成  
ここでは`iac-on-gcp-case1-prod`,`iac-on-gcp-case1-stg`という名前のプロジェクトを作成し、`iac-on-gcp-case1-stg`を選択
- 以下のAPIを有効化する  
  - 課金
  - Identity and Access Management (IAM) API
- Terraform操作用のサービスアカウントを手動で作成  
ここでは `infra` という名前のアカウントを作成  
さらにIAMに移動してサービスアカウントをメンバーに追加&以下の権限を追加  
  - ストレージ -> ストレージ管理者
  - IAM -> セキュリティ管理者
  - Service Accounts -> サービスアカウントの管理者
アカウントの作成が完了したら、JSON鍵を作成。鍵ファイルが自動的にダウンロードされる(以降の説明ではこの鍵を`/path/to/downloaded-keyfile.json`とする)。  
- 以下のコマンドでローカル上でサービスアカウントをアクティベート  
```bash
# NNNは手順実行環境に依存した値
$ gcloud auth activate-service-account infra-NNN@iac-on-gcp-case1-stg-NNN.iam.gserviceaccount.com --key-file /path/to/downloaded-keyfile.json
$ gcloud config set project iac-on-gcp-case1-stg-NNN
$ gcloud config set compute/region asia-northeast1
$ gcloud config set compute/zone asia-northeast1-a
$ gcloud config list
```
- Terraformのtfstateファイルを保存するバケットをGCSに手動で作成  
ここでは`iac-on-hgcp-case1-terraform`という名前のバケットを作成  
```bash
$ gsutil mb -c multi_regional -l Asia gs://stg-iac-on-gcp-case1-terraform
$ gsutil ls gs://
$ gsutil versioning set on gs://stg-iac-on-gcp-case1-terraform
```

- Terraform用のディレクトリを構成
```
- iac-on-gcp
  |- case1
    |- terraform
      |- modules
      |- stacks
        |- prod
        |- stg
...
```


- 初回起動時に最低限必要なTerraformの定義ファイルを適切なディレクトリ配下に作成
```hcl-terraform
# ./terraform/stacks/stg/terraform.tf
terraform {
  required_version = "= v0.12.8"
}


# ./terraform/stacks/stg/provider.tf
provider "google" {
  version = "~> 2.15"
  project = "${var.project}"
  region  = "asia-northeast1"
}

# ./terraform/stacks/stg/backend.tf
terraform {
  backend "gcs" {
    bucket = "iac-on-gcp-case1-terraform"
  }
}

# ./terraform/stacks/stg/variable.tf
locals {
  service = "iac-on-gcp-case1"
  env     = "stg"
}

variable "project" {}
```
- Terraformの初期化
```bash
# NNNは手順実行環境に依存した値
$ export TF_VAR_project=iac-on-gcp-case1-stg-NNN
$ export GOOGLE_CREDENTIALS=/path/to/downloaded-keyfile.json
$ cd /path/to/iac-on-gcp/case1/terraform/stacks/stg
$ terraform init
```
- 手動で作成したTerraformのバケットやサービスアカウントをTerraform管理下に置くために、modulesディレクトリと定義ファイルを作成&terraform import  
```bash
$ mkdir -p /path/to/iac-on-gcp/case1/terraform/modules/storage/common
$ mkdir -p /path/to/iac-on-gcp/case1/terraform/modules/iam/common
```

```hcl-terraform
# ./modules/storage/terraform-backend/main.tf
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

# ./modules/iam/common/main.tf
resource "google_service_account" "infra" {
  account_id   = "infra-NNN"
  display_name = "infra"
}

# ./stacks/stg/storage.tf
module "storage-common" {
  source  = "../../modules/storage/common"
  service = "${local.service}"
  env     = "${local.env}"
}

# ./stacks/stg/iam.tf
module "iam-common" {
  source = "../../modules/iam/common"
}
```

```bash
$ terraform import module.storage-common.google_storage_bucket.terraform-backend stg-iac-on-gcp-case1-terraform
$ terraform import module.iam-common.google_service_account.infra infra-NNN@iac-on-gcp-case1-stg-NNN.iam.gserviceaccount.com
```
