output "table_name" {
  value = aws_dynamodb_table.onboarding_tasks.name
}

output "table_arn" {
  value = aws_dynamodb_table.onboarding_tasks.arn
}
