data "aws_caller_identity" "current" {}

variable "module_name" {
  default = "nexus-repository"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "ecs_ami_map" {
  type = "map"
  default = {
    us-west-1      = "ami-9ad4dcfa"
    us-west-2      = "ami-1d668865"
    us-east-1      = "ami-a7a242da"
    us-east-2      = "ami-b86a5ddd"
    eu-west-1      = "ami-0693ed7f"
    eu-west-2      = "ami-f4e20693"
    eu-west-3      = "ami-698b3d14"
    eu-central-1   = "ami-698b3d14"
    ap-northeast-1 = "ami-68ef940e"
    ap-northeast-2 = "ami-a5dd70cb"
    ap-southeast-1 = "ami-0a622c76"
    ca-central-1   = "ami-5ac94e3e"
    ap-south-1     = "ami-2e461a41"
    sa-east-1      = "ami-d44008b8"
  }
}

variable "ecs_instance_type" {
  default = "t2.medium"
}

variable "nexus_repository_tag" {
  default = "latest"
}

# See ../variables.yaml
# Redefined here just in case
variable "allowed_cidrs" {
  type = "list"
  default = ["0.0.0.0/28"]
}

variable "route53_zone_id" {}
variable "route53_zone_name" {}
variable "nexus_vpc_cidr" {
  default = "172.16.0.0/24"
}

variable "az_map" {
  type = "list"
  default = [
    { az          = "us-west-2a",
      subnet_cidr = "172.16.0.0/28"
    },
    { az          = "us-west-2b",
      subnet_cidr = "172.16.0.16/28"
    }
  ]
}

variable "num_azs" {
  default = 2
}

variable "efs_mountpoint" {
  default = "/mnt/efs"
}

variable "efs_nexus_storage" {
  default = "/mnt/efs/nexus"
}

variable "nexus_hostport" {
  default = 80
}

variable "nexus_containerport" {
  default = 8081
}

variable "sensu_vpc_id" {
  default = "vpc-redacted"
}

variable "sensu_vpc_cidr" {
  default = "172.16.1.0/24"
}

variable "sensu_sg_id" {
  default = "sg-redacted"
}
