resource "aws_vpc" "sensu_cluster_vpc" {
    cidr_block           = "${var.sensu_cluster_vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    tags {
      Name = "${var.module_name}-vpc"
    }
}

/**
 * Internet gateway for main VPC
 */
resource "aws_internet_gateway" "sensu_cluster_gw" {
    vpc_id = "${aws_vpc.sensu_cluster_vpc.id}"
}
resource "aws_subnet" "sensu_cluster_subnets" {
  count                   = "${var.num_azs}"
  vpc_id                  = "${aws_vpc.sensu_cluster_vpc.id}"
  cidr_block              = "${lookup(var.az_map[count.index], "subnet_cidr")}"
  availability_zone       = "${lookup(var.az_map[count.index], "az")}"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "sensu_cluster_routingtable" {
  vpc_id = "${aws_vpc.sensu_cluster_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sensu_cluster_gw.id}"
  }

  route {
    vpc_peering_connection_id = "${var.nexus_sensu_peering_cnxn}"
    cidr_block                = "${var.nexus_vpc_cidr}"
  }
}

resource "aws_route_table_association" "sensu_cluster_routingtableassoc" {
  count          = "${var.num_azs}"
  subnet_id      = "${element(aws_subnet.sensu_cluster_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.sensu_cluster_routingtable.id}"
}
