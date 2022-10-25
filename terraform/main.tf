terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

module "database" {
  source       = "./modules/database"
  dynamo_table = var.dynamo_table
}

module "check_package" {
  for_each = local.checkers

  source             = "./modules/lambda_check_version"
  lambda_root        = "../lambdas/checks/${each.key}"
  package_check_name = each.key
  dynamo_arn         = module.database.dynamodb_table_arn
  dynamo_table       = var.dynamo_table
  release_offset     = var.release_offset
}

module "notify" {
  source            = "./modules/lambda_notify"
  lambda_root       = "../lambdas/notify"
  dynamo_arn        = module.database.dynamodb_table_arn
  dynamo_stream_arn = module.database.dynamodb_table_stream_arn
  notify_email      = var.notify_email
  notify_sms        = var.notify_sms
}

locals {
  # Create a set of directory names containing the lambda checkers
  checkers = toset([for i in fileset("../lambdas/checks/", "*/main.py") : dirname(i)])
}