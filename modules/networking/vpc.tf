#
# VPC Resources
#  * VPC --> /16
#  * Subnets --> 2 Public 2 Private
#  * Internet Gateway --> 1 IGW
#  * Route Table --> 4 Route tables
#  * EIP --> 1 EIP for NAT
#  * NAT --> 1 NAT
#


# vpc

resource "aws_vpc" "app_vpc" {
  #count = var.vpc_id == "" ? 1 : 0
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags       = merge(var.tags, { Name = "vpc-${var.eks_cluster_name}" })
  lifecycle {
    ignore_changes = [cidr_block, enable_dns_hostnames ]
  }
}

# Returns all avaliable AZs
# IGW
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-Igw" })
  lifecycle {
    ignore_changes = [vpc_id]
  }
}

# create both public and private subnets
resource "aws_subnet" "public" {
  count = 2
  availability_zone       = "${var.availability_zones[count.index]}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 7 , count.index + 2 )}" #element(var.public_subnet_cidr_list, count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.app_vpc.id
  lifecycle {
    ignore_changes = [availability_zone, cidr_block, vpc_id]
  }
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-public-subnet-${count.index}",
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared", # tag required for eks cluster to recognize subnets
    "kubernetes.io/role/elb"                        = 1        # tag is required for rxternal load balancer
  })
}

resource "aws_subnet" "private" {
  count = 2
  availability_zone = "${var.availability_zones[count.index]}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr, 3 , count.index + 1)}" #element(var.private_subnet_cidr_list, count.index)
  vpc_id            = aws_vpc.app_vpc.id
  lifecycle {
    ignore_changes = [availability_zone, cidr_block, vpc_id]
  }
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-private-subnet-${count.index}",
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared", #  tag required for eks cluster to recognize subnets
    "kubernetes.io/role/internal-elb"               = 1        #  tag is required for internal load balancer
  })
}


# create 2 NAT gateway and associate them with each public subnet
resource "aws_eip" "eip1" {
  # EIP may require IGW to exist prior to association.
  # Use depends_on to set an explicit dependency on the IGW.
  depends_on = [aws_internet_gateway.app_igw]
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_eip" "eip2" {
  # EIP may require IGW to exist prior to association.
  # Use depends_on to set an explicit dependency on the IGW.
  depends_on = [aws_internet_gateway.app_igw]
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = aws_subnet.public[1].id
  tags          = merge(var.tags, { Name = "${var.eks_cluster_name}-NATgw-2" })
  lifecycle {
    ignore_changes = [allocation_id, subnet_id]
  }
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.public[0].id
  lifecycle {
    ignore_changes = [allocation_id, subnet_id]
  }
  tags          = merge(var.tags, { Name = "${var.eks_cluster_name}-NATgw-1" })
}

# public Route table
resource "aws_route_table" "public1" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
  timeouts {
    create = "10m"
    delete = "10m"
  }
  lifecycle {
    ignore_changes = all
  }
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-Public-Route-Table-1" })
}

resource "aws_route_table" "public2" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
  timeouts {
    create = "10m"
    delete = "10m"
  }
  lifecycle {
    ignore_changes = all
  }
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-Public-Route-Table-2" })
}


# private route tables
resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }
  timeouts {
    create = "10m"
    delete = "10m"
  }
  lifecycle {
    ignore_changes = all
  }
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-Private-Route-Table-1" })
}

resource "aws_route_table" "private2" {
  # The VPC ID.
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat2.id #aws_nat_gateway.nat2.id
  }
  timeouts {
    create = "10m"
    delete = "10m"
  }
  lifecycle {
    ignore_changes = all
  }
  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-Private-Route-Table-2" })
}

# Route table association
resource "aws_route_table_association" "publci1" {
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public1.id
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public[1].id
  route_table_id = aws_route_table.public2.id
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private1.id
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private[1].id
  route_table_id = aws_route_table.private2.id
  lifecycle {
    ignore_changes = all
  }
}

