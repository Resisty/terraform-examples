resource "aws_route53_zone" "devops_route53_zone" {
  name    = "${var.devops_route53_zone}"
  comment = "Zone for Devops"
}

resource "aws_route53_record" "devops_ns" {
  zone_id = "${aws_route53_zone.devops_route53_zone.zone_id}"
  name = "${var.devops_route53_zone}"
  type = "NS"
  ttl = "30"
  records = [
    "${aws_route53_zone.devops_route53_zone.name_servers.0}",
    "${aws_route53_zone.devops_route53_zone.name_servers.1}",
    "${aws_route53_zone.devops_route53_zone.name_servers.2}",
    "${aws_route53_zone.devops_route53_zone.name_servers.3}"
  ]
}
