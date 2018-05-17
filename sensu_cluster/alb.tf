resource "aws_lb" "sensu_cluster_lb" {
  name                       = "${var.module_name}-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.sensu_cluster_lb_sg.id}"]
  subnets                    = ["${aws_subnet.sensu_cluster_subnets.*.id}"]
  enable_deletion_protection = true
}

resource "aws_lb_target_group" "sensu_cluster_web" {
  name     = "${var.module_name}-web-tgtgrp"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.sensu_cluster_vpc.id}"
}

resource "aws_lb_listener" "sensu_cluster_web_443" {
  load_balancer_arn = "${aws_lb.sensu_cluster_lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2015-05"
  certificate_arn = "${aws_acm_certificate_validation.sensu_cluster_certificate_validation.certificate_arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.sensu_cluster_web.arn}"
    type             = "forward"
  }
}

