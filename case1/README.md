# iac-on-gcp

## 初期手順

- プロジェクトを手動で作成  
ここでは`iac-on-gcp-case1-prod`,`iac-on-gcp-case1-stg`という名前のプロジェクトを作成  
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
$ gcloud config list
```
- Terraformのtfstateファイルを保存するバケットをGCSに手動で作成  
ここでは`iac-on-hgcp-case1-terraform`という名前のバケットを作成  
```bash
$ gsutil mb -c multi_regional -l Asia gs://iac-on-gcp-case1-terraform
$ gsutil ls gs://
$ gsutil versioning set on gs://iac-on-gcp-case1-terraform
```
- 初回起動時に最低限必要なTerraformの定義ファイルを適切なディレクトリ配下に作成
```hcl-terraform
# provider.tf
provider "google" {
  version = "~> 2.15"
  project = "${var.project}"
  region = "asia-northeast1"
}

# backend.tf
terraform {
  backend "gcs" {
    bucket = "iac-on-gcp-case1-terraform"
  }
}

# variable.tf
variable "project" {}
```
- Terraformの初期化およびワークスペースの設定  
```bash
# NNNは手順実行環境に依存した値
$ export TF_VAR_project=iac-on-gcp-case1-stg-NNN
$ export GOOGLE_CREDENTIALS=/path/to/downloaded-keyfile.json
$ terraform init
$ terraform workspace new stg
```
- 手動で作成したTerraformのバケットやサービスアカウントをTerraform管理下に置くために、定義ファイルを作成&terraform import  
```hcl-terraform
# storage.tf
resource "google_storage_bucket" "iac-on-gcp-case1-terraform" {
  name     = "iac-on-gcp-case1-terraform"
  location = "ASIA"
  storage_class = "MULTI_REGIONAL"
  versioning {
    enabled = true
  }
}

# iam.tf
resource "google_service_account" "infra" {
  account_id   = "infra-NNN"
  display_name = "infra"
}
```
```bash
$ terraform import google_storage_bucket.iac-on-gcp-case1-terraform iac-on-gcp-case1-terraform
$ terraform import google_service_account.infra infra-NNN@iac-on-gcp-case1-stg-NNN.iam.gserviceaccount.com
```
