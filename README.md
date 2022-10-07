# Terraform: Create AWS Two-Teir Architecture
Terraform-AWS: Week 18 practice project two tier architecture 

1. Deploy a VPC with CIDR 10.0.0.0/16 with 2 public subnets with CIDR 10.0.1.0/24 and 10.0.2.0/24. Each public subnet should be in a different AZ for high availability.
2. Create 2 private subnet with CIDR '10.0.3.0/24' and '10.0.4.0/24' with an RDS MySQL instance (micro) in one of the subnets. 
Each private subnet should be in a different AZ. A load balancer that will direct traffic to the public subnets.
3. Deploy 1 EC2 t2.micro instance in each public subnet.

** Add a variables.tf file and make sure nothing is hardcoded in your main.tf.
** Use count to reduce the number of resource blocks for your public subnets and your ec2 instances.
