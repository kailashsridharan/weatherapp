variable "eks_cluster_name" {
  default = ""
  type    = string
}

variable "vpc_id" {
  type    = string
  default = ""
}


variable "subnet_ids" {
  type    = list(string)
  default = []
}


variable tags {
  type    = map(string)
  default = {}
}

variable "instance_type" {
  type    = string
  default = "m5.4xlarge"
}

variable "subnet_cidr_list" {
  type    = list(string)
  default = []
}

