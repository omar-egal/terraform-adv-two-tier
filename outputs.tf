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
  value = [aws_instance.web_instances[*].id]
}

output "db_id" {
  value = aws_db_instance.mysqldb.id
}

output "instance_public_IPv4_addr" {
  value = [aws_instance.web_instances[*].public_ip]
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

