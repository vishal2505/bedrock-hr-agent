variable "project_name" {
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

variable "documents_bucket_arn" {
  type = string
}

variable "vector_bucket_arn" {
  description = "ARN of the S3 Vectors bucket used as the Knowledge Base vector store"
  type        = string
}

variable "dynamodb_table_arn" {
  type = string
}

