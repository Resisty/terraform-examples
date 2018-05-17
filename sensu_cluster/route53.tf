resource "aws_route53_record" "sensu_cluster_cert_validation_record" {
  name    = "${aws_acm_certificate.sensu_cluster_certificate.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.sensu_cluster_certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.route53_zone_id}"
  ttl     = 60
  type    = "CNAME"
  records = ["${aws_acm_certificate.sensu_cluster_certificate.domain_validation_options.0.resource_record_value}"]
}

resource "aws_route53_record" "sensu_cluster_address_name" {
  name    = "${var.module_name}.${var.route53_zone_name}"
  zone_id = "${var.route53_zone_id}"
  type    = "A"
  alias {
    name                   = "${aws_lb.sensu_cluster_lb.dns_name}"
    zone_id                = "${aws_lb.sensu_cluster_lb.zone_id}"
    evaluate_target_health = true
  }
}
