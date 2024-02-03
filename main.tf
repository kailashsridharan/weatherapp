provider "aws" {
  region = var.region
}

module "networking" {
  source = "./modules/networking"
  availability_zones       = var.availability_zones # flatten(data.aws_availability_zones.available.*.names)
  vpc_cidr                 = var.vpc_cidr
  eks_cluster_name         = var.eks_cluster_name
  tags                     = var.tags
}

module "cluster"{
  source = "./modules/eks-cluster"
  eks_cluster_name = var.eks_cluster_name
  vpc_id = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  subnet_cidr_list =  module.networking.subnet_cidr_list
  instance_type = var.instance_type
  tags = var.tags
}

