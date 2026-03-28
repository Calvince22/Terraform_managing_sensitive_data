terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "grace-zawadi-terraform-state-2026"
    key            = "day13/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# VARIABLES
# -----------------------------

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

# -----------------------------
# DATA SOURCES (Secrets Manager)
# -----------------------------

data "aws_secretsmanager_secret" "db_credentials" {
  name = "dev/db/credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# -----------------------------
# LOCALS
# -----------------------------

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}

# -----------------------------
# RDS DATABASE
# -----------------------------

resource "aws_db_instance" "example" {
  identifier         = "secure-db-demo"
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = var.instance_class
  allocated_storage  = 10
  db_name            = var.db_name

  username = local.db_creds["username"]
  password = local.db_creds["password"]

  skip_final_snapshot = true

  publicly_accessible = true
}

# -----------------------------
# OUTPUTS
# -----------------------------

output "db_endpoint" {
  value       = aws_db_instance.example.endpoint
  description = "Database endpoint"
}

output "db_username" {
  value       = local.db_creds["username"]
  sensitive   = true
}

output "db_password" {
  value       = local.db_creds["password"]
  sensitive   = true
}