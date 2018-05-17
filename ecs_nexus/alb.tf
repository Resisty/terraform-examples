resource "aws_lb" "nexus_lb" {
  name                       = "${var.module_name}-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.nexus_lb_sg.id}"]
  subnets                    = ["${aws_subnet.nexus_subnets.*.id}"]
  enable_deletion_protection = true
}

resource "aws_lb_target_group" "nexus_web" {
  name     = "${var.module_name}-web-tgtgrp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.nexus_vpc.id}"
}

resource "aws_lb_listener" "nexus_web_443" {
  load_balancer_arn = "${aws_lb.nexus_lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2015-05"
  certificate_arn = "${aws_acm_certificate_validation.nexus_certificate_validation.certificate_arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.nexus_web.arn}"
    type             = "forward"
  }
}

