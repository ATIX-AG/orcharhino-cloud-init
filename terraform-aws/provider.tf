terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }
}


# AWS Provider configuration

provider "aws" {
  region = "eu-central-1"
}
