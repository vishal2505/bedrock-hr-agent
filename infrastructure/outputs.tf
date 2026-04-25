output "bedrock_agent_id" {
  description = "Bedrock Agent ID"
  value       = module.bedrock.agent_id
}

output "bedrock_agent_alias_id" {
  description = "Bedrock Agent Alias ID (production)"
  value       = module.bedrock.agent_alias_id
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = module.bedrock.knowledge_base_id
}

output "documents_bucket" {
  description = "S3 bucket for HR policy documents"
  value       = module.s3.documents_bucket_id
}

output "frontend_bucket" {
  description = "S3 bucket for frontend static files"
  value       = module.s3.frontend_bucket_id
}

output "frontend_url" {
  description = "Frontend website URL"
  value       = "http://${module.s3.frontend_website_endpoint}"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for onboarding tasks"
  value       = module.dynamodb.table_name
}


output "vector_bucket_name" {
  description = "S3 Vectors bucket name for the Knowledge Base"
  value       = module.s3vectors.vector_bucket_name
}

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard name"
  value       = "${var.project_name}-dashboard"
}

output "app_backend_policy_arn" {
  description = "Attach this managed policy to the IAM user whose credentials are in backend/.env"
  value       = module.iam.app_backend_policy_arn
}
