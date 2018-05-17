data "aws_caller_identity" "current" {}

variable "module_name" {
  default = "sensu-cluster"
}

variable "aws_region" {
  default = "us-west-2"
}

# Note: these are all hvm:ebs-ssd AMIs
# Chosen for at least t2.medium instances
variable "ubuntu_ami_map" {
  type = "map"
  default = {
    us-west-1      = "ami-44273924"
    us-west-2      = "ami-b5ed9ccd"
    us-east-1      = "ami-e80f8397"
    us-east-2      = "ami-cf172aaa"
  }
}

variable "ecs_instance_type" {
  default = "t2.medium"
}

# See ../variables.yaml
# Redefined here just in case
variable "allowed_cidrs" {
  type = "list"
  default = ["0.0.0.0/28"]
}

variable "route53_zone_id" {}
variable "route53_zone_name" {}
variable "sensu_cluster_vpc_cidr" {
  default = "172.16.1.0/24"
}

variable "az_map" {
  type = "list"
  default = [
    { az          = "us-west-2a",
      subnet_cidr = "172.16.1.0/28"
    },
    { az          = "us-west-2b",
      subnet_cidr = "172.16.1.16/28"
    }
  ]
}

variable "num_azs" {
  default = 2
}

variable "kms_key_arn" {
  default = "arn:aws:kms:us-west-2:REDACTED:key/ALSO_REDACTED"
}

variable "ansible_bucket_object_key" {
  default = "sensu_ansible.zip"
}

variable "ansible_hosts_file_name" {
  default = "hosts"
}

variable "ansible_playbook_file_name" {
  default = "playbook.yml"
}

variable "nexus_tag_name" {
  default = "aws:autoscaling:groupName"
}

variable "nexus_vpc_cidr" {}

variable "nexus_sensu_peering_cnxn" {}

variable "nexus_tag_value" {
  default = "nexus-repository-asg"
}
