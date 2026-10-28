terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state layout is documented in docs/state.md. Fill these values with
  # -backend-config so the bucket and table are not hard-coded per environment.
  #
  # backend "s3" {
  #   key            = "prod/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   use_lockfile   = true
  # }
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
    CostCenter  = var.cost_center
  }
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  az_count           = 3
  enable_nat_gateway = true
  tags               = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                         = "${local.name}-db"
  instance_class               = var.db_instance_class
  allocated_storage            = 100
  vpc_id                       = module.network.vpc_id
  subnet_ids                   = module.network.private_subnet_ids
  ingress_security_group_ids   = [module.service.service_security_group_id]
  password                     = var.db_password
  multi_az                     = true
  deletion_protection          = true
  backup_retention_period      = 14
  performance_insights_enabled = true
  tags                         = local.tags
}

module "service" {
  source = "../../modules/ecs-service"

  cluster_name       = "${local.name}-cluster"
  service_name       = "${local.name}-api"
  container_image    = var.container_image
  container_port     = 8080
  cpu                = "1024"
  memory             = "2048"
  desired_count      = 3
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  log_retention_days = 90

  environment = {
    APP_ENV      = var.environment
    LOG_LEVEL    = "info"
    SERVICE_NAME = "${local.name}-api"
  }

  tags = local.tags
}

module "alarms" {
  source = "../../modules/alarms"

  name_prefix             = local.name
  ecs_cluster_name        = module.service.cluster_name
  ecs_service_name        = module.service.service_name
  rds_instance_id         = module.rds.resource_id
  alb_arn_suffix          = var.alb_arn_suffix
  target_group_arn_suffix = var.target_group_arn_suffix
  rds_free_storage_bytes  = 21474836480
  ecs_cpu_threshold       = 70
  ecs_memory_threshold    = 75
  target_latency_ms       = 1500
  alert_emails            = var.alert_emails
  tags                    = local.tags
}

module "site" {
  source = "../../modules/static-site"

  name            = local.name
  bucket_name     = "${local.name}-site-${var.bucket_suffix}"
  domain_name     = var.site_domain
  certificate_arn = var.site_certificate_arn
  price_class     = "PriceClass_200"
  tags            = local.tags
}

module "budget" {
  source = "../../modules/budget"

  name                = "${local.name}-monthly"
  limit_amount        = var.monthly_budget
  notification_emails = var.alert_emails
  thresholds          = [50, 80, 100]
  tags                = local.tags
}
