terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.54.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}
}

module "ecs-cluster" {
  source = "git@github.com:companieshouse/terraform-library-ecs-cluster.git?ref=1.1.4"

  stack_name  = local.stack_name
  environment = var.environment
  name_prefix = local.name_prefix

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = local.application_subnet_ids

  asg_max_instance_count     = var.asg_max_instance_count
  asg_min_instance_count     = var.asg_min_instance_count
  asg_desired_instance_count = var.asg_desired_instance_count

  ec2_key_pair_name = var.ec2_key_pair_name
  ec2_image_id      = var.ec2_image_id
  ec2_instance_type = var.ec2_instance_type

  enable_container_insights = var.enable_container_insights
}
