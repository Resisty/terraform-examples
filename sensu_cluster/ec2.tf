resource "aws_iam_instance_profile" "sensu_cluster_instance_profile" {
  name = "${var.module_name}-instance-profile"
  role = "${aws_iam_role.sensu_cluster_instance_role.name}"
}

resource "aws_key_pair" "sensu_cluster_instance_keypair" {
  # See ../kms.tf for private key
  # secret "static_analysis_ecs_instance_private_key"
  key_name   = "${var.module_name}-instance-keypair"
  public_key = "ssh-rsa long-ass-rsa-key"
}

data "template_file" "sensu_cluster_launchconfig_userdata_doc" {
  template =  "${file("${path.module}/templates/sensu_cluster_launchconfig_userdata.tpl")}"
  vars {
    bucket      = "${aws_s3_bucket.sensu_cluster_bucket.id}"
    zipfile     = "${var.ansible_bucket_object_key}"
    hosts_file  = "${var.ansible_hosts_file_name}"
    playbook    = "${var.ansible_playbook_file_name}"
  }
}

resource "aws_launch_configuration" "sensu_cluster_lc" {
  image_id               = "${var.ubuntu_ami_map["${var.aws_region}"]}"
  instance_type          = "${var.ecs_instance_type}"
  key_name               = "${aws_key_pair.sensu_cluster_instance_keypair.key_name}"
  security_groups        = ["${aws_security_group.sensu_cluster_instance_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.sensu_cluster_instance_profile.name}"
  lifecycle {
    create_before_destroy = true
  }
  user_data              = "${data.template_file.sensu_cluster_launchconfig_userdata_doc.rendered}"
  depends_on             = ["aws_s3_bucket_object.sensu_cluster_ansible_zip_object"]
}


# Convert az_map into multiple templates containing only az names
data "template_file" "sensu_cluster_az_ids" {
  count    = "${var.num_azs}"
  template = "${lookup(var.az_map[count.index], "az")}"
}

resource "aws_autoscaling_group" "sensu_cluster_asg" {
  availability_zones   = ["${data.template_file.sensu_cluster_az_ids.*.rendered}"]
  name                 = "${var.module_name}-asg"
  max_size             = 2
  min_size             = 2
  launch_configuration = "${aws_launch_configuration.sensu_cluster_lc.name}"
  desired_capacity     = 2
  vpc_zone_identifier  = ["${aws_subnet.sensu_cluster_subnets.*.id}"]
  target_group_arns    = ["${aws_lb_target_group.sensu_cluster_web.*.arn}"]
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
