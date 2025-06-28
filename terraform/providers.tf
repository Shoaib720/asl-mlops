terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0-beta3"
    }
  }
  backend "s3" {
    bucket         = "all-project-tfstates-07062025"
    key            = "tf/mlops.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "all-project-tfstate-locks-07062025"  # Optional but recommended
  }
}

provider "aws" {
  region = "ap-south-1"
}