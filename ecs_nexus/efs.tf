resource "aws_efs_file_system" "nexus_persist_storage" {
  creation_token = "${var.module_name}-persistant-storage"
}

resource "aws_efs_mount_target" "nexus_mount_target" {
  count           = "${var.num_azs}"
  file_system_id  = "${aws_efs_file_system.nexus_persist_storage.id}"
  subnet_id       = "${element(aws_subnet.nexus_subnets.*.id, count.index)}"
  security_groups = ["${aws_security_group.nexus_efs_sg.id}"]
}
