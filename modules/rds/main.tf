locals {
  is_production = var.deletion_protection
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-subnets"
  description = "Private subnets for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-subnets" })
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "PostgreSQL access for ${var.name}; ingress only from listed security groups."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_security_group_ids

    content {
      description     = "PostgreSQL from ${ingress.value}"
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Responses to established connections"
  }

  tags = merge(var.tags, { Name = "${var.name}-database" })
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-params"
  family      = var.parameter_group_family
  description = "SSL-enforcing parameters for ${var.name}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier = var.name

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "18:00-19:00"
  maintenance_window      = "sun:19:00-sun:20:00"

  performance_insights_enabled = var.performance_insights_enabled

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !local.is_production
  final_snapshot_identifier = local.is_production ? "${var.name}-final" : null

  auto_minor_version_upgrade = true
  apply_immediately         = false

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${var.name}/postgresql"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
