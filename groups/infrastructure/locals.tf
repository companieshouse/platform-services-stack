locals {
  stack_name     = "platform-service"
  stack_fullname = "${local.stack_name}-stack"
  name_prefix    = "${local.stack_name}-${var.environment}"

  stack_secrets = jsondecode(data.vault_generic_secret.secrets.data_json)
  
  vpc_name                   = local.stack_secrets["vpc_name"]
  application_subnet_pattern = local.stack_secrets["application_subnet_pattern"]
  application_subnet_ids     = join(",", data.aws_subnets.application.ids)
}