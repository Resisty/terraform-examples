resource "aws_iam_instance_profile" "nexus_instance_profile" {
  name = "${var.module_name}-instance-profile"
  role = "${aws_iam_role.nexus_repository_ecs_execute_role.name}"
}

resource "aws_key_pair" "nexus_instance_keypair" {
  # See ../kms.tf for private key
  # secret "static_analysis_ecs_instance_private_key"
  key_name   = "${var.module_name}-instance-keypair"
  public_key = "ssh-rsa long-ass-rsa-key-here"
}

data "template_file" "nexus_launchconfig_userdata_doc" {
  template =  "${file("${path.module}/templates/nexus_launchconfig_userdata.tpl")}"
  vars {
    mountpoint  = "${var.efs_mountpoint}"
    efs_dnsname = "${aws_efs_file_system.nexus_persist_storage.dns_name}"
    storagedir  = "${var.efs_nexus_storage}"
    clustername = "${aws_ecs_cluster.nexus_repository_cluster.name}"
  }
}

resource "aws_launch_configuration" "nexus_lc" {
  name                   = "${var.module_name}-launchconfig"
  image_id               = "${var.ecs_ami_map["${var.aws_region}"]}"
  instance_type          = "${var.ecs_instance_type}"
  key_name               = "${aws_key_pair.nexus_instance_keypair.key_name}"
  security_groups        = ["${aws_security_group.nexus_instance_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.nexus_instance_profile.name}"
  lifecycle {
    create_before_destroy = true
  }
  user_data              = "${data.template_file.nexus_launchconfig_userdata_doc.rendered}"
}


# Convert az_map into multiple templates containing only az names
data "template_file" "nexus_az_ids" {
  count    = "${var.num_azs}"
  template = "${lookup(var.az_map[count.index], "az")}"
}

resource "aws_autoscaling_group" "nexus_asg" {
  availability_zones   = ["${data.template_file.nexus_az_ids.*.rendered}"]
  name                 = "${var.module_name}-asg"
  max_size             = 2
  min_size             = 2
  launch_configuration = "${aws_launch_configuration.nexus_lc.name}"
  desired_capacity     = 2
  vpc_zone_identifier  = ["${aws_subnet.nexus_subnets.*.id}"]
  target_group_arns    = ["${aws_lb_target_group.nexus_web.*.arn}"]
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
  lifecycle {
    create_before_destroy = true
  }
}

output "nexus_tag_value" {
  value = "${aws_autoscaling_group.nexus_asg.name}"
}
