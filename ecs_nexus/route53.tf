resource "aws_route53_record" "nexus_cert_validation_record" {
  name    = "${aws_acm_certificate.nexus_certificate.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.nexus_certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.route53_zone_id}"
  ttl     = 60
  type    = "CNAME"
  records = ["${aws_acm_certificate.nexus_certificate.domain_validation_options.0.resource_record_value}"]
}

resource "aws_route53_record" "nexus_address_name" {
  name    = "${var.module_name}.${var.route53_zone_name}"
  zone_id = "${var.route53_zone_id}"
  type    = "A"
  alias {
    name                   = "${aws_lb.nexus_lb.dns_name}"
    zone_id                = "${aws_lb.nexus_lb.zone_id}"
    evaluate_target_health = true
  }
}
