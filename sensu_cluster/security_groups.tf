resource "aws_security_group" "sensu_cluster_lb_sg" {
  name = "${var.module_name}-lb-sg"
  description = "Security group for sensu_cluster lb for ${var.module_name}"
  vpc_id = "${aws_vpc.sensu_cluster_vpc.id}"

  # SSH access from some network
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "${var.allowed_cidrs}"
  }

  # HTTPS from various networks
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = "${var.allowed_cidrs}"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sensu_cluster_instance_sg" {
  name = "${var.module_name}-instance-sg"
  description = "Security group for sensu_cluster instance for ${var.module_name}"
  vpc_id = "${aws_vpc.sensu_cluster_vpc.id}"

  # HTTP access from Load Balancer security groups
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    security_groups = ["${aws_security_group.sensu_cluster_lb_sg.id}"]
  }

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "${var.allowed_cidrs}"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
