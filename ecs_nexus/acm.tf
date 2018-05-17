resource "aws_acm_certificate" "nexus_certificate" {
  domain_name = "${var.module_name}.${var.route53_zone_name}"
  validation_method = "DNS"
  tags {
    Environment = "${var.module_name}-${var.route53_zone_name}"
  }
}

resource "aws_acm_certificate_validation" "nexus_certificate_validation"{
  certificate_arn = "${aws_acm_certificate.nexus_certificate.arn}"
  validation_record_fqdns = ["${aws_route53_record.nexus_cert_validation_record.fqdn}"]
}
