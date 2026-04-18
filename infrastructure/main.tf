terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "hr-onboarding-terraform-state"
    key    = "terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# --- Core Storage ---
module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# --- App Data ---
module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "OnboardingTasks"
  tags       = var.tags
}

# --- Email ---
module "ses" {
  source       = "./modules/ses"
  sender_email = var.sender_email
}

# --- Vector Store (S3 Vectors) ---
module "s3vectors" {
  source       = "./modules/s3vectors"
  project_name = var.project_name
}

# --- IAM (shared roles/policies) ---
module "iam" {
  source = "./modules/iam"

  project_name         = var.project_name
  tags                 = var.tags
  bedrock_model_id     = var.bedrock_model_id
  embedding_model_id   = var.embedding_model_id
  documents_bucket_arn = module.s3.documents_bucket_arn
  vector_bucket_arn    = module.s3vectors.vector_bucket_arn
  dynamodb_table_arn   = module.dynamodb.table_arn
}

# --- Action Group Lambdas ---
module "lambda" {
  source = "./modules/lambda"

  project_name        = var.project_name
  tags                = var.tags
  send_email_role_arn = module.iam.lambda_send_email_role_arn
  log_task_role_arn   = module.iam.lambda_log_task_role_arn
  sender_email        = var.sender_email
  dynamodb_table_name = module.dynamodb.table_name
}

# --- Bedrock (agent, guardrails, knowledge base) ---
module "bedrock" {
  source = "./modules/bedrock"

  project_name         = var.project_name
  aws_region           = var.aws_region
  tags                 = var.tags
  bedrock_model_id     = var.bedrock_model_id
  embedding_model_id   = var.embedding_model_id
  agent_role_arn       = module.iam.bedrock_agent_role_arn
  kb_role_arn          = module.iam.knowledge_base_role_arn
  documents_bucket_arn = module.s3.documents_bucket_arn
  vector_bucket_arn    = module.s3vectors.vector_bucket_arn
  send_email_lambda_arn = module.lambda.send_email_arn
  log_task_lambda_arn   = module.lambda.log_task_arn
}

# --- Observability ---
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name             = var.project_name
  aws_region               = var.aws_region
  tags                     = var.tags
  agent_id                 = module.bedrock.agent_id
  send_email_function_name = module.lambda.send_email_function_name
  log_task_function_name   = module.lambda.log_task_function_name
  dynamodb_table_name      = module.dynamodb.table_name
}
