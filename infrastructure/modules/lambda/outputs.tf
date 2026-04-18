output "send_email_arn" {
  value = aws_lambda_function.send_email.arn
}

output "log_task_arn" {
  value = aws_lambda_function.log_task.arn
}

output "send_email_function_name" {
  value = aws_lambda_function.send_email.function_name
}

output "log_task_function_name" {
  value = aws_lambda_function.log_task.function_name
}
