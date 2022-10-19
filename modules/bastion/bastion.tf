data "aws_ami" "linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_iam_instance_profile" "bastion_ec2_profile" {
  name = "BastionInstanceProfile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.linux2.id
  instance_type               = var.instance_type["type1"]
  subnet_id                   = var.public_subnet[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_ec2_profile.name
  associate_public_ip_address = true

  user_data = <<EOF
  #!/bin/bash
  yum update -y
  yum install telnet -y
  yum install jq -y
  EOF

  tags = { Name = "${var.name_prefix}-bastion" }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
    tags                  = { Name = "${var.name_prefix}-ebs" }
  }
}