variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "agent_id" {
  type = string
}

variable "send_email_function_name" {
  type = string
}

variable "log_task_function_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}
