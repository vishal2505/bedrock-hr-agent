# --- Log Group ---
resource "aws_cloudwatch_log_group" "bedrock_agent" {
  name              = "/aws/bedrock/agent/${var.project_name}"
  retention_in_days = 30

  tags = var.tags
}

# --- Dashboard ---
resource "aws_cloudwatch_dashboard" "hr_agent" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Bedrock Agent Invocations"
          metrics = [
            ["AWS/Bedrock", "Invocations", "AgentId", var.agent_id]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Bedrock Agent Latency (p50/p99)"
          metrics = [
            ["AWS/Bedrock", "InvocationLatency", "AgentId", var.agent_id, { stat = "p50" }],
            ["AWS/Bedrock", "InvocationLatency", "AgentId", var.agent_id, { stat = "p99" }]
          ]
          period = 300
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Lambda Error Rates"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", var.send_email_function_name, { stat = "Sum" }],
            ["AWS/Lambda", "Errors", "FunctionName", var.log_task_function_name, { stat = "Sum" }]
          ]
          period = 300
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "DynamoDB Write Count"
          metrics = [
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", var.dynamodb_table_name, { stat = "Sum" }]
          ]
          period = 300
          region = var.aws_region
          view   = "timeSeries"
        }
      }
    ]
  })
}
