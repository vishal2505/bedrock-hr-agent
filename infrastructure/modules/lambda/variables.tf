variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "send_email_role_arn" {
  type = string
}

variable "log_task_role_arn" {
  type = string
}

variable "sender_email" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}
