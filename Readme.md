# 🔐 Secure Secrets Management with Terraform (AWS RDS + Secrets Manager)

## 📌 Overview

This project demonstrates how to securely manage sensitive data in Terraform by integrating **AWS Secrets Manager** with an **RDS MySQL database deployment**.

Instead of hardcoding credentials or exposing them in variables, secrets are:

* Stored securely in AWS Secrets Manager
* Retrieved dynamically at runtime
* Hidden from Terraform output using `sensitive = true`
* Protected in a remote encrypted state backend

---

## 🎯 Objective

To deploy a MySQL RDS instance while ensuring:

* No secrets are stored in `.tf` files
* No secrets are committed to Git
* No secrets are exposed in CLI output
* State file is securely managed

---

## 🏗️ Architecture

```
AWS Secrets Manager → Terraform → RDS (MySQL)
                        ↓
                 S3 Remote State (Encrypted)
                        ↓
                 DynamoDB (State Locking)
```

---

## 🔐 Secret Storage (AWS Secrets Manager)

Secrets are created manually (not via Terraform) to avoid bootstrapping risks.

### Create Secret

```bash
aws secretsmanager create-secret \
  --name "dev/db/credentials" \
  --secret-string '{"username":"admin","password":"StrongPass123"}'
```

---

## 📥 Fetching Secrets in Terraform

### Data Sources

```hcl
data "aws_secretsmanager_secret" "db_credentials" {
  name = "dev/db/credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}
```

---

## 🔄 Decoding Secret

```hcl
locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.db_credentials.secret_string
  )
}
```

This allows access to:

* `local.db_creds["username"]`
* `local.db_creds["password"]`

---

## 🗄️ RDS Database Deployment

```hcl
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
```

### ✅ Key Security Points

* No credentials in Terraform code
* Secrets injected at runtime
* Clean separation of infrastructure and secrets

---

## 🔒 Sensitive Outputs

```hcl
output "db_username" {
  value     = local.db_creds["username"]
  sensitive = true
}

output "db_password" {
  value     = local.db_creds["password"]
  sensitive = true
}
```

### Terraform Output Example:

```
(sensitive value)
```

✔ Prevents exposure in logs and CLI

---

## 🛡️ Remote State Configuration

```hcl
backend "s3" {
  bucket         = "terraform-state-2026"
  key            = "day13/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-locks"
  encrypt        = true
}
```

---

## 🔐 State Security Features

* ✅ Encryption at rest (AES-256)
* ✅ DynamoDB locking (prevents race conditions)
* ✅ IAM-restricted access
* ✅ No local state file usage

---

## ⚠️ The Three Secret Leak Paths (Solved)

### 1. Hardcoded Secrets

❌ Avoided by using Secrets Manager

---

### 2. Variable Defaults

❌ No secrets stored in variables

---

### 3. Terraform State

⚠️ Still contains secrets → mitigated by:

* S3 encryption
* IAM access control

---

## 📁 Recommended `.gitignore`

```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
```

---

## 🚀 How to Run

### 1. Initialize Terraform

```bash
terraform init
```

---

### 2. Preview Changes

```bash
terraform plan
```

---

### 3. Apply Infrastructure

```bash
terraform apply
```

---

## 🧠 Key Learnings

* Secrets should never be stored in Terraform files
* AWS Secrets Manager is the safest way to manage credentials
* `sensitive = true` only hides output, not state
* State file security is critical in production systems
* Infrastructure and secrets must be decoupled

---

## ⚠️ Important Notes

* RDS instance is publicly accessible (for demo purposes only)
* In production:

  * Use private subnets
  * Disable public access
  * Use stronger IAM policies

---

## 🎯 Conclusion

This project demonstrates a **secure Terraform workflow** where:

* Secrets are managed externally
* Infrastructure remains clean and reusable
* Sensitive data is protected at every stage

This is a foundational DevOps skill required for production-grade infrastructure.

---

## 🔥 Author

Day 13 — Terraform Challenge
Secure Infrastructure & Secrets Management
