# --- Tasks Table ---
resource "aws_dynamodb_table" "onboarding_tasks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "task_id"

  attribute {
    name = "task_id"
    type = "S"
  }

  tags = var.tags
}
