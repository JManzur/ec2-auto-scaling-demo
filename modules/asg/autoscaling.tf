data "aws_ami" "linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-Instance-Profile"
  role = aws_iam_role.role.name
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data/user_data.sh.tpl")

  vars = {
    name_prefix = var.name_prefix
    aws_region  = var.aws_region
    app_port    = var.demo_app["port"]
  }
}

locals {
  resources_tags = ["volume", "network-interface"]
}

resource "aws_launch_template" "app" {
  name_prefix            = "${var.name_prefix}-Launch-Template-"
  image_id               = data.aws_ami.linux2.id
  instance_type          = var.instance_type["type1"]
  key_name               = var.key_name
  user_data              = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [aws_security_group.internal.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  dynamic "tag_specifications" {
    for_each = toset(local.resources_tags)
    content {
      resource_type = tag_specifications.key
      tags = {
        Name = "${var.name_prefix}"
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  count               = 2
  name                = count.index == 0 ? "Farm-1" : "Farm-2"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  health_check_type   = "ELB"
  vpc_zone_identifier = [var.private_subnet[0], var.private_subnet[1]]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "DeploymentDate (UTC)"
    value               = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
    propagate_at_launch = true
  }

  tag {
    key                 = "Farm"
    value               = count.index == 0 ? "1" : "2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = count.index == 0 ? "Farm-1-Instance" : "Farm-2-Instance"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
    # triggers = ["tag"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "attachment" {
  count                  = 2
  autoscaling_group_name = aws_autoscaling_group.app[count.index].id
  lb_target_group_arn    = aws_lb_target_group.app[count.index].arn
}

##### Autoscaling Policy #####

# Scale UP by 1 if the average CPU utilization is equal to or greater than 50%
resource "aws_autoscaling_policy" "scale_up" {
  count                  = 2
  name                   = count.index == 0 ? "Farm-1-Scale-Up" : "Farm-2-Scale-Up"
  autoscaling_group_name = aws_autoscaling_group.app[count.index].id
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  count               = 2
  alarm_name          = count.index == 0 ? "Farm-1-Scale-Up" : "Farm-2-Scale-Up"
  alarm_description   = "Monitors CPU utilization for APP ASG"
  alarm_actions       = [aws_autoscaling_policy.scale_up[count.index].arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = 50
  evaluation_periods  = 1
  period              = 60
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app[count.index].id
  }
}

# Scale DOWN by 1 if the average CPU utilization is less than or equal to 50%
resource "aws_autoscaling_policy" "scale_down" {
  count                  = 2
  name                   = count.index == 0 ? "Farm-1-Scale-Down" : "Farm-2-Scale-Down"
  autoscaling_group_name = aws_autoscaling_group.app[count.index].id
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  count               = 2
  alarm_name          = count.index == 0 ? "Farm-1-Scale-Down" : "Farm-2-Scale-Down"
  alarm_description   = "Monitors CPU utilization for APP ASG"
  alarm_actions       = [aws_autoscaling_policy.scale_down[count.index].arn]
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = 50
  evaluation_periods  = 1
  period              = 60
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app[count.index].id
  }
}