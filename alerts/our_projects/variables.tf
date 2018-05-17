variable "es_domain_arn" {}

variable "severity" {
  default = "info"
}

variable "pd_api_key" {
  default = ""
}

variable "test_pd_api_key" {
  default = ""
}

# MUST BE OVERRIDDEN
variable "logs_alarm_sub" {}

variable "kibana_proxy" {
  default = "https://proxy.example.com"
}

variable "module_name" {
  default = "default"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "logs_pusher_name" {
  default = "logs-pusher"
}

variable "unittest_threshold" {
	default = 20
}

variable "gitfat_threshold" {
	default = 0
}

variable "diskfull_threshold" {
	default = 0
}

variable "general_threshold" {
	default = 0
}

variable "default_lambda_timezone" {
	default = "US/Pacific"
}

variable "offhours_lambda_email_addresses" {
  default = "devops@example.com"
}

variable "offhours_lambda_registered_address" {
  default = "offhours@example.com"
}

variable "enable_offhours" {
	default = ""
}

variable "create_alerts" {
  default = true
  description = "A boolean to determine whether or not to create Kinesis Analytics stack(s) and requisit Kinesis output streams."
}
