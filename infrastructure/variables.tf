variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hr-onboarding"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "sender_email" {
  description = "Verified SES email address for sending welcome emails"
  type        = string
}

variable "frontend_url" {
  description = "Frontend URL for CORS configuration"
  type        = string
  default     = "http://localhost:3000"
}

variable "bedrock_model_id" {
  description = "Bedrock foundation model ID for the agent"
  type        = string
  default     = "us.amazon.nova-pro-v1:0"
}

variable "embedding_model_id" {
  description = "Bedrock embedding model ID for the knowledge base"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "enable_backend_service" {
  description = "Whether to create the App Runner backend service. Set false on first apply (so ECR exists), true on second apply after the image has been pushed."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "hr-onboarding-agent"
    ManagedBy   = "terraform"
  }
}
