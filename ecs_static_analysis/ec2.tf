resource "aws_iam_instance_profile" "update_es_from_static_analysis_profile" {
  name = "${var.module_name}-update_es_from_static_analysis_profile"
  role = "${aws_iam_role.static_analysis_s3_to_sqs_ecs_execute_role.name}"
}

resource "aws_key_pair" "update_es_from_static_analysis_keypair" {
  key_name   = "${var.module_name}-update_es_from_static_analysis_keypair"
  public_key = "ssh-rsa long-ass-rsa-key"
}
resource "aws_security_group" "allow_ssh" {
  name = "${var.module_name}-ssh_access"
  description = "Simple SSH access security group"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "update_es_from_static_analysis_instance_lc" {
  name_prefix                 = "${var.module_name}-update_es_from_static_analysis-"
  image_id                    = "${var.ecs_ami_map["${var.aws_region}"]}"
  instance_type               = "${var.ecs_instance_type}"
  key_name                    = "${aws_key_pair.update_es_from_static_analysis_keypair.key_name}"
  security_groups             = ["${aws_security_group.allow_ssh.id}"]
  enable_monitoring           = true
  placement_tenancy           = "default"
  iam_instance_profile        = "${aws_iam_instance_profile.update_es_from_static_analysis_profile.name}"
  user_data                   = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.update_es_from_static_analysis_cluster.name} >> /etc/ecs/ecs.config
sudo yum update -y ecs-init
EOF
}

resource "aws_autoscaling_group" "update_es_from_static_analysis_instance_asg" {
  name                      = "${var.module_name}-update_es_from_static_analysis_instance_asg"
  availability_zones        = ["${var.aws_region}a", "${var.aws_region}b"]
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.update_es_from_static_analysis_instance_lc.name}"
  enabled_metrics      = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.module_name}-UpdateESFromStaticAnalysisASG"
    propagate_at_launch = true
  }
}
