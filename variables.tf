variable "eks_cluster_name" {
  type    = string
  default = "weatherapp" ### Do not Change this as the Python Code depends on this
}

variable "region" {
  type    = string
  default = "us-east-1" #Make sure this is the same as the python input
}

variable "vpc_cidr" {
  type    = string
  default = "10.90.0.0/16"
}

variable tags {
  type = map(string)
  default = {
    userName = "Kailash sridharan"
  }
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  type    = string
  default = "m5.4xlarge"
}
