variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "enable" {
  description = "Whether to create the App Runner service. Set to false on first apply (before image is pushed), true after."
  type        = bool
  default     = false
}

variable "app_backend_policy_arn" {
  description = "ARN of the IAM policy granting Bedrock + DynamoDB access to the backend"
  type        = string
}

variable "agent_id" {
  type = string
}

variable "agent_alias_id" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "frontend_url" {
  description = "Frontend URL for backend CORS configuration"
  type        = string
}
