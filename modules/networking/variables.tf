variable "eks_cluster_name" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16" # This is set to /16 to avoid the math on the public and private subnets
}

variable tags {
  type = map(string)
  default = {}
}
variable "availability_zones" {
  type    = list(string)
  default = []
}