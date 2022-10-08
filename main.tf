# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "Week-18-${var.AWS-Two-Teir-Architecture}-OmarEgal"
  }
}

# Create VPC Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet_Gateway"
  }
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_sbn_cidr_ranges)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.public_sbn_cidr_ranges, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "public-sbn-${count.index + 1}"
    Tier = "Public"
  }
}


# Create private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_sbn_cidr_ranges)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private_sbn_cidr_ranges, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "private-sbn-${count.index + 1}"
    Tier = "Private"
  }
}

# Create a route to the internet
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Create association for public route
resource "aws_route_table_association" "public_sbn_association" {
  count          = length(var.public_sbn_cidr_ranges)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route.id
}

# Create a security group for web access
resource "aws_security_group" "web_sg" {
  name        = "alb_sg"
  description = "Allow HTTP/S inbound traffic from igw"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_inbound_web_traffic"
  }
}

# Create database security group
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow inbound traffic from web tier"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Allow inbound traffic from web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.web_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_inbound_web_traffic"
  }
}

# Create Application Load Balancer
resource "aws_lb" "alb" {
  name               = "web-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

  enable_deletion_protection = false

}

# Create target group
resource "aws_lb_target_group" "alb_tg" {
  name     = "tf-web-lb-tg"
  port     = var.port
  protocol = var.protocol
  vpc_id   = aws_vpc.vpc.id

}

data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Create ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.port
  protocol          = var.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# Attach target group to instnaces
resource "aws_lb_target_group_attachment" "alb_tg_attm" {
  count            = length(var.public_sbn_cidr_ranges)
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.web_instances[count.index].id
  port             = var.port
}

# Create EC2 instnaces in each AZ
resource "aws_instance" "web_instances" {
  depends_on = [aws_internet_gateway.igw]

  count                       = length(var.public_sbn_cidr_ranges)
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = var.instance_type
  vpc_security_group_ids      = ["${aws_security_group.web_sg.id}"]
  subnet_id                   = element(aws_subnet.public_subnets[*].id, count.index)
  availability_zone           = element(aws_subnet.public_subnets[*].availability_zone, count.index)
  user_data                   = file("bootstrap.sh")
  tags = {
    Name = "web_instance-${count.index + 1}"
    Tier = "Web"
  }
}

# Create MySQL db instance
resource "aws_db_instance" "mysqldb" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  availability_zone    = element(var.availability_zones, 1)
}
