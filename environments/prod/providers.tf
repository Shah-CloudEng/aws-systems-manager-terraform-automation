terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "linuxautomation-tfstate-339713094763"
    key     = "prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "LinuxAutomation"
      Environment = "Capstone"
      ManagedBy   = "SSM"
      Owner       = "DevOps-Team"
      Repository  = "aws-systems-manager-linux-automation"
    }
  }
}
