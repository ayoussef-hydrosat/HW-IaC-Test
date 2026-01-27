# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id


  # Allow PostgreSQL access from ECS tasks
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow PostgreSQL access from bastion host
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project_name}-rds-sg"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Security group for bastion host
resource "aws_security_group" "bastion" {
  name        = "${local.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  # Allow SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project_name}-bastion-sg"
    Environment = local.environment
    Project     = local.project_name
  }
}

# RDS subnet group
resource "aws_db_subnet_group" "postgresql" {
  name       = "${local.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets


  tags = {
    Name        = "${local.project_name}-db-subnet-group"
    Environment = local.environment
    Project     = local.project_name
  }
  depends_on = [module.vpc]
}

# RDS parameter group
resource "aws_db_parameter_group" "postgresql" {
  name   = "${local.project_name}-postgresql"
  family = "postgres17"

  # We are in private subnets, we can disable SSL
  parameter {
    name  = "rds.force_ssl"
    value = "0"

  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgresql" {
  identifier = "${local.project_name}-postgresql"

  engine         = "postgres"
  engine_version = "17.5"
  instance_class = local.db_instance_class

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = local.db_name
  username = local.db_username
  password = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)["password"]

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.postgresql.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot  = true
  parameter_group_name = aws_db_parameter_group.postgresql.name

  tags = {
    Name        = "${local.project_name}-postgresql"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Bastion host EC2 instance
resource "aws_instance" "bastion" {
  #Amazon Linux 2023, x86_64, 64-bit
  ami           = "ami-00475f7c6f4a7e5cd"
  instance_type = "t3.micro"

  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  key_name = var.ssh_key_name

  tags = {
    Name        = "${local.project_name}-bastion"
    Environment = local.environment
    Project     = local.project_name
  }
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id  = aws_secretsmanager_secret.rds_password.id
  depends_on = [aws_secretsmanager_secret_version.rds_password]
} 