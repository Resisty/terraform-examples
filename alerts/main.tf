module "some_alerts_project" {
  source           = "./our_projects"
  logs_pusher_name = "${var.logs_pusher_name}"
  es_domain_arn    = "${var.es_domain_arn}"
  aws_region       = "${var.aws_region}"
  module_name      = "sensu-logs-prod"
  logs_alarm_sub   = "${var.logs_alarm_sub}"
  create_alerts    = false
}
