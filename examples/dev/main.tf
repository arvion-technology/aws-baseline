terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  az_count           = 2
  enable_nat_gateway = false
  tags               = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                         = "${local.name}-db"
  instance_class               = "db.t3.micro"
  allocated_storage            = 20
  vpc_id                       = module.network.vpc_id
  subnet_ids                   = module.network.private_subnet_ids
  ingress_security_group_ids   = [module.service.service_security_group_id]
  password                     = var.db_password
  multi_az                     = false
  deletion_protection          = false
  backup_retention_period      = 1
  performance_insights_enabled = false
  tags                         = local.tags
}

module "service" {
  source = "../../modules/ecs-service"

  cluster_name       = "${local.name}-cluster"
  service_name       = "${local.name}-api"
  container_image    = var.container_image
  container_port     = 8080
  cpu                = "256"
  memory             = "512"
  desired_count      = 1
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  log_retention_days = 7

  environment = {
    APP_ENV      = var.environment
    LOG_LEVEL    = "debug"
    SERVICE_NAME = "${local.name}-api"
  }

  tags = local.tags
}

module "alarms" {
  source = "../../modules/alarms"

  name_prefix            = local.name
  ecs_cluster_name       = module.service.cluster_name
  ecs_service_name       = module.service.service_name
  rds_instance_id        = module.rds.resource_id
  rds_free_storage_bytes = 2147483648
  alert_emails           = var.alert_emails
  tags                   = local.tags
}

module "site" {
  source = "../../modules/static-site"

  name        = local.name
  bucket_name = "${local.name}-site-${var.bucket_suffix}"
  tags        = local.tags
}

module "budget" {
  source = "../../modules/budget"

  name                = "${local.name}-monthly"
  limit_amount        = var.monthly_budget
  notification_emails = var.alert_emails
  thresholds          = [80, 100]
  tags                = local.tags
}
