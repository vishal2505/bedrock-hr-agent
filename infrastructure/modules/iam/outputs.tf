output "bedrock_agent_role_arn" {
  value = aws_iam_role.bedrock_agent.arn
}

output "knowledge_base_role_arn" {
  value = aws_iam_role.knowledge_base.arn
}

output "lambda_send_email_role_arn" {
  value = aws_iam_role.lambda_send_email.arn
}

output "lambda_log_task_role_arn" {
  value = aws_iam_role.lambda_log_task.arn
}

output "app_backend_policy_arn" {
  description = "Attach this policy to the IAM user whose credentials are in backend/.env"
  value       = aws_iam_policy.app_backend.arn
}
