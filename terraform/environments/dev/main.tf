# main.tf — Dev environment
# Calls the networking and EKS modules using the same MiniStack-pointed provider

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    ec2      = "http://localhost:4566"
    eks      = "http://localhost:4566"
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

module "networking" {
  source = "../../modules/networking"
}

module "eks" {
  source     = "../../modules/eks"
  vpc_id     = module.networking.vpc_id
  subnet_ids = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.networking.vpc_id
}
