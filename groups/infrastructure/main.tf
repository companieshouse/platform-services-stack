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

resource "aws_kms_alias" "ecs" {
  name          = "alias/${var.environment}/${local.stack_fullname}"
  target_key_id = aws_kms_key.ecs.key_id
}

resource "aws_kms_key" "ecs" {
  description             = "${var.environment} KMS ECS key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "alb" {
  source = "git@github.com:companieshouse/terraform-modules//aws/application_load_balancer?ref=1.0.205"

  environment         = var.environment
  service             = "stack"
  ssl_certificate_arn = data.aws_acm_certificate.cert.arn
  subnet_ids          = split(",", local.application_subnet_ids)
  vpc_id              = data.aws_vpc.vpc.id

  create_security_group  = true
  ingress_cidrs          = ["0.0.0.0/0"]
  redirect_http_to_https = true
  service_configuration = {
    default = {
      listener_config = {
        default_action_type = "fixed-response"
        port                = 443
      }
    }
  }
}

module "ecs-cluster" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-cluster?ref=feature/ecs-configure-task-definition"

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
