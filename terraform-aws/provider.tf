terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }

#  # Gitlab backend
#  backend "http" {
#    address = "https://{GITLAB_URL}/api/v4/projects/{PROJECT_ID}/terraform/state/main"
#    lock_address = "https://{GITLAB_URL}/api/v4/projects/{PROJECT_ID}/terraform/state/main/lock"
#    unlock_address = "https://{{GITLAB_URL}}/api/v4/projects/{PROJECT_ID}/terraform/state/main/lock"
#    lock_method = "POST"
#    unlock_method = "DELETE"
#  }

#  # AWS S3 backend
#  backend "s3" {
#    bucket = "mybucket"
#    key    = "path/to/my/key"
#    region = "us-east-1"
#  }

}


# AWS Provider configuration

provider "aws" {
  region = "eu-central-1"
}
