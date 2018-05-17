resource "aws_cloudwatch_metric_alarm" "es_freediskspace" {
  alarm_name                = "logs-es-free-disk-space"
  comparison_operator       = "LessThanOrEqualToThreshold"
  # 6 times in a row every ten minutes => Affected for an hour
  evaluation_periods        = "6"
  period                    = "600"
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/ES"
  statistic                 = "Average"
  # (Size of domain in gb) * .9 * (1024 mb/gb) / 10 => 10% of non-reserved space (90% of total?) free
  threshold                 = "${var.elasticsearch_ebs_size * 0.9 * 1024 / 10}"
  alarm_description         = "This metric monitors free disk space on the ES domain."
  # This is a hardcoded var instead of a created resource
  # see variables.yaml for a note about why
  alarm_actions             = ["${var.logs_metrics_alarms_sub_arn}"]
  insufficient_data_actions = ["${var.logs_metrics_alarms_sub_arn}"]
  ok_actions                = ["${var.logs_metrics_alarms_sub_arn}"]

  dimensions {
    DomainName = "${aws_elasticsearch_domain.es.domain_name}"
    ClientId   = "${data.aws_caller_identity.current.account_id}"
  }
}
