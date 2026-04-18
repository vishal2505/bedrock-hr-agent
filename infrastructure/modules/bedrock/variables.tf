variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "bedrock_model_id" {
  type = string
}

variable "embedding_model_id" {
  type = string
}

variable "agent_role_arn" {
  type = string
}

variable "kb_role_arn" {
  type = string
}

variable "documents_bucket_arn" {
  type = string
}

variable "vector_bucket_arn" {
  description = "ARN of the S3 Vectors bucket used as the Knowledge Base vector store"
  type        = string
}

variable "send_email_lambda_arn" {
  type = string
}

variable "log_task_lambda_arn" {
  type = string
}
