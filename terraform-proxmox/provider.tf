terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
  }
# Gitlab backend
  backend "http" {
    # address = "https://{GITLAB_URL}/api/v4/projects/{PROJECT_ID}/terraform/state/main"
    # lock_address = "https://{GITLAB_URL}/api/v4/projects/{PROJECT_ID}/terraform/state/main/lock"
    # unlock_address = "https://{{GITLAB_URL}}/api/v4/projects/{PROJECT_ID}/terraform/state/main/lock"
    # lock_method = "POST"
    # unlock_method = "DELETE"
  }
#   AWS S3 backend
#   terraform {
#   backend "s3" {
#     bucket = "mybucket"
#     key    = "path/to/my/key"
#     region = "us-east-1"
#   }
# }
}


provider "proxmox" {
  pm_api_url  = var.pm_api_url
  pm_user     = var.pm_user          
  pm_password = var.pm_password        
}
