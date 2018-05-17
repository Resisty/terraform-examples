variable "logs_pusher_name" {
  default = "logs-pusher"
}

variable "es_domain_arn" {}

variable "aws_region" {
  default = "us-west-2"
}

variable "pd_api_key" {}
variable "test_pd_api_key" {}
variable "logs_alarm_sub" {}
