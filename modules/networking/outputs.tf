output "public_subnet_cidr" {
  value = aws_subnet.public.*.cidr_block
}

output "private_subnet_cidr" {
  value = aws_subnet.private.*.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "subnet_ids" {
  value = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)
}

output "subnet_cidr_list" {
  value = concat(aws_subnet.public.*.cidr_block, aws_subnet.private.*.cidr_block)
}

output "availability_zones" {
  value = aws_subnet.private.*.availability_zone
}

output "igw_id" {
  value = aws_internet_gateway.app_igw.id 
}

output "public_route_table_1" {
  value = aws_route_table.public1.id
}

output "public_route_table_2" {
  value = aws_route_table.public2.id
}

output "private_route_table_1" {
  value = aws_route_table.private1.id
}

output "private_route_table_2" {
  value = aws_route_table.private2.id
}

output "vpc_id" {
  value = aws_vpc.app_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.app_vpc.cidr_block
}