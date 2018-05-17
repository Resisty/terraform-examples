data "aws_caller_identity" "current" {}
module "logs_es_cleanup" {
  source           = "./logs_es_cleanup"
  es_endpoint = "${aws_elasticsearch_domain.es.endpoint}"
  es_domain_arn = "${aws_elasticsearch_domain.es.arn}"
}

module "alerts" {
  source              = "./alerts"
  logs_pusher_name    = "${aws_iam_user.logs-pusher.name}"
  es_domain_arn  = "${aws_elasticsearch_domain.es.arn}"
  aws_region          = "${var.aws_region}"
  pd_api_key          = "${data.aws_kms_secret.devops_pagerduty_keys.pd_api_key}"
  test_pd_api_key     = "${data.aws_kms_secret.devops_pagerduty_keys.test_pd_api_key}"
  logs_alarm_sub = "${var.logs_metrics_alarms_sub_arn}"  
}

module "ecs_static_analysis" {
  source                      = "./ecs_static_analysis"
  account_dead_queue          = "${aws_sqs_queue.account_dead_queue.arn}"
  es_endpoint                 = "${aws_elasticsearch_domain.es.endpoint}"
  es_endpoint_arn             = "${aws_elasticsearch_domain.es.arn}"
  slack_token                 = "${data.aws_kms_secret.static_analysis_slack_tokens.devops_slack_token}"
  chunk_size                  = 50
  static_analysis_updater_tag = "v1"
}

# BEFORE COPYING/INSTANTIATING THIS MODULE:
# READ THE MODULE'S README
# ./ecs_nexus/README.md
module "ecs_nexus" {
  source            = "./ecs_nexus"
  route53_zone_id   = "${aws_route53_zone.devops_route53_zone.zone_id}"
  route53_zone_name = "${var.devops_route53_zone}"
  nexus_vpc_cidr    = "${var.nexus_vpc_cidr}"
  num_azs           = 2
  az_map            = [
    { 
      az          = "us-west-2a"
      subnet_cidr = "${lookup("${var.nexus_vpc_subnet_cidrs}", "us-west-2a")}"
    },
    { 
      az          = "us-west-2b"
      subnet_cidr = "${lookup("${var.nexus_vpc_subnet_cidrs}", "us-west-2b")}"
    }
  ]
  allowed_cidrs     = "${var.allowed_cidrs}"
}

module "sensu_cluster" {
  source                   = "./sensu_cluster"
  route53_zone_id          = "${aws_route53_zone.devops_route53_zone.zone_id}"
  route53_zone_name        = "${var.devops_route53_zone}"
  sensu_cluster_vpc_cidr   = "${var.sensu_cluster_vpc_cidr}"
  kms_key_arn              = "${aws_kms_key.lambda_env_key.arn}"
  nexus_vpc_cidr           = "${var.nexus_vpc_cidr}"
  nexus_sensu_peering_cnxn = "${module.ecs_nexus.nexus_sensu_peering_cnxn}"
  nexus_tag_value          = "${module.ecs_nexus.nexus_tag_value}"
}
