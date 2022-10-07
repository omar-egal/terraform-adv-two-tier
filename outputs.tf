output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnets[*].id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnets[*].id]
}

output "instance_ids" {
  value = [aws_instance.web_instance[*].id]
}

output "instance_public_IPv4_addr" {
  value = [aws_instance.web_instance[*].public_ip]
}

