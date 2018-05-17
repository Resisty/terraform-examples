resource "aws_acm_certificate" "sensu_cluster_certificate" {
  domain_name = "${var.module_name}.${var.route53_zone_name}"
  validation_method = "DNS"
  tags {
    Environment = "${var.module_name}-${var.route53_zone_name}"
  }
}

resource "aws_acm_certificate_validation" "sensu_cluster_certificate_validation"{
  certificate_arn = "${aws_acm_certificate.sensu_cluster_certificate.arn}"
  validation_record_fqdns = ["${aws_route53_record.sensu_cluster_cert_validation_record.fqdn}"]
}
