output "dashboard_arn" {
  value = aws_cloudwatch_dashboard.hr_agent.dashboard_arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.bedrock_agent.name
}
