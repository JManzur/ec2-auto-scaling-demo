data "http" "myip" {
  url = "https://ifconfig.co/"
}

## SG Rule: Form User IP > ALB
resource "aws_security_group" "external" {
  name        = "${var.name_prefix}-External-SG"
  description = "From Internet to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "From Internet to ALB"
    protocol    = "tcp"
    from_port   = var.demo_app["port"]
    to_port     = var.demo_app["port"]
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    description      = "Allow Internet Out"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-External-SG" }
}

## SG Rule: VPC > App
resource "aws_security_group" "internal" {
  name        = "${var.name_prefix}-Internal-SG"
  description = "From VPC to EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "From VPC to EC2"
    protocol    = "tcp"
    from_port   = var.demo_app["port"]
    to_port     = var.demo_app["port"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow PING"
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow Internet Out"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-Internal-SG" }
}