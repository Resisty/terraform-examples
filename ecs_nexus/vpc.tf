resource "aws_vpc" "nexus_vpc" {
    cidr_block           = "${var.nexus_vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    tags {
      Name = "${var.module_name}-vpc"
    }
}

resource "aws_vpc_peering_connection" "sensu_vpc_peering_cnxn" {
  vpc_id      = "${var.sensu_vpc_id}"
  peer_vpc_id = "${aws_vpc.nexus_vpc.id}"
  auto_accept = true
}

resource "aws_route_table" "sensu_to_nexus_route" {
  vpc_id = "${var.sensu_vpc_id}"
  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.sensu_vpc_peering_cnxn.id}"
    cidr_block                = "${var.nexus_vpc_cidr}"
  }
}

/**
 * Internet gateway for main VPC
 */
resource "aws_internet_gateway" "nexus_gw" {
    vpc_id = "${aws_vpc.nexus_vpc.id}"
}
resource "aws_subnet" "nexus_subnets" {
  count                   = "${var.num_azs}"
  vpc_id                  = "${aws_vpc.nexus_vpc.id}"
  cidr_block              = "${lookup(var.az_map[count.index], "subnet_cidr")}"
  availability_zone       = "${lookup(var.az_map[count.index], "az")}"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "nexus_routingtable" {
  vpc_id = "${aws_vpc.nexus_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.nexus_gw.id}"
  }

  route {
    vpc_peering_connection_id = "${aws_vpc_peering_connection.sensu_vpc_peering_cnxn.id}"
    cidr_block                = "${var.sensu_vpc_cidr}"
  }
}

resource "aws_route_table_association" "nexus_routingtableassoc" {
  count          = "${var.num_azs}"
  subnet_id      = "${element(aws_subnet.nexus_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.nexus_routingtable.id}"
}

output "nexus_sensu_peering_cnxn" {
  value = "${aws_vpc_peering_connection.sensu_vpc_peering_cnxn.id}"
}
