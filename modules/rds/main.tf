resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_access" {
  name        = "${var.environment}-rds-access-sg"
  description = "Allow access to RDS from ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow access from ECS tasks"
    from_port       = 5432 # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-rds-access-sg"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  allocated_storage    = var.allocated_storage
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  identifier           = "${var.environment}-${var.db_name}"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_access.id]
  skip_final_snapshot  = true
  publicly_accessible  = false # Crucial for security

  tags = {
    Name        = "${var.environment}-${var.db_name}-db"
    Environment = var.environment
  }
}