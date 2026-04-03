# ─────────────────────────────────────────────────────────────
# Terraform Main Configuration
# Provider: AWS
# Resources: VPC, EKS, IAM, Security Groups
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Backend: Store state in S3
  # Uncomment after creating S3 bucket manually
  # backend "s3" {
  #   bucket = "qtec-task-terraform-state"
  #   key    = "qtec-task/terraform.tfstate"
  #   region = "ap-southeast-1"
  # }
}

# ─── AWS Provider ─────────────────────────────────────────────
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "qtec-task"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "devops"
    }
  }
}

# ─── Data Sources ─────────────────────────────────────────────
# Get available AZs in region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}