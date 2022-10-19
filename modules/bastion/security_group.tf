data "http" "myip" {
  url = "https://ifconfig.co/"
}

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-Bastion-SG"
  description = "SSH and HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH Form User IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
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
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name_prefix}-Bastion-SG" }
}