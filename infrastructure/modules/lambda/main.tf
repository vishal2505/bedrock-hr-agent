# --- Package Lambda Sources ---
data "archive_file" "send_email" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/send_email"
  output_path = "${path.module}/files/send_email.zip"
}

data "archive_file" "log_task" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/log_task"
  output_path = "${path.module}/files/log_task.zip"
}

# --- Lambda Functions ---
resource "aws_lambda_function" "send_email" {
  function_name    = "hr-send-welcome-email"
  filename         = data.archive_file.send_email.output_path
  source_code_hash = data.archive_file.send_email.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  role             = var.send_email_role_arn

  environment {
    variables = {
      SENDER_EMAIL = var.sender_email
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "log_task" {
  function_name    = "hr-log-onboarding-task"
  filename         = data.archive_file.log_task.output_path
  source_code_hash = data.archive_file.log_task.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  role             = var.log_task_role_arn

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }

  tags = var.tags
}

# --- Permissions: Bedrock Agent -> Lambda ---
resource "aws_lambda_permission" "allow_bedrock_send_email" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_email.function_name
  principal     = "bedrock.amazonaws.com"
}

resource "aws_lambda_permission" "allow_bedrock_log_task" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_task.function_name
  principal     = "bedrock.amazonaws.com"
}

# --- Log Groups ---
resource "aws_cloudwatch_log_group" "send_email" {
  name              = "/aws/lambda/${aws_lambda_function.send_email.function_name}"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "log_task" {
  name              = "/aws/lambda/${aws_lambda_function.log_task.function_name}"
  retention_in_days = 14

  tags = var.tags
}
