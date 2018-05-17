data "aws_caller_identity" "current" {}

variable "account_dead_queue" {}

variable "es_endpoint" {}

variable "es_endpoint_arn" {}

variable "aws_region" {
  default = "us-west-2"
}

variable "chunk_size" {
  default = 100
}

variable "report_pattern" {
  default = "report-.*\\.html"
}

variable "cppcheck_pattern" {
  default = "scan-cppcheck.txt"
}

variable "email_pattern" {
  default = "email.txt"
}

variable "ses_registered_address" {
  default = "contact@example.com"
}

variable "slack_pattern" {
  default = "slack.txt"
}

variable "slack_team" {
  default = "our_team"
}

variable "slack_bot" {
  default = "devops_bot"
}

variable "slack_token" {}

variable "module_name" {
  default = "static-analysis"
}

variable "ecs_ami_map" {
  type = "map"
  default = {
    us-west-2 = "ami-1d668865"
  }
}

variable "ecs_instance_type" {
  default = "t2.medium"
}

variable "static_analysis_updater_tag" {
  default = "latest"
}
