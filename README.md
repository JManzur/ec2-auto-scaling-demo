
# EC2 Auto Scaling POC - Blue/Green Strategy  

## Resources deployed by this manifest:

### Deployment diagram:

![App Screenshot](images/placeholder.png)

## Tested with: 

| Environment | Application | Version  |
| ----------------- |-----------|---------|
| WSL2 Ubuntu 20.04 | Terraform | v1.3.1  |

## Initialization How-To:

Located in the root directory, make an "aws configure" to log into the aws account, and a "terraform init" to download the necessary modules and start the backend.

```bash
aws configure
terraform init
```

## Deployment How-To:

Located in the root directory, make the necessary changes in the variables.tf file and run the manifests:

```bash
terraform apply
```
## Deployment How-To:

Located in the root directory, create a file called default.auto.tfvars with a content like the following:

```bash
aws_profile = "SomeProfile"
aws_region  = "us-east-1"
name_prefix = "ASG-Demo"
key_name    = "SomeKeyPair"
```

Initialice the direcotry to download the necessary modules and start the backend.

```bash
terraform init
```

## Deployment How-To:

Located in the root directory, run the following command:

```bash
terraform apply
```
## Integration with a Golden AMI:

```bash
### Fetch the latest Golden AMI
data "aws_ami" "my_golden_ami" {
  most_recent = true
  name_regex  = "^My-Golden-AMI-.*"
  owners      = ["0123456789123"] # The ID of the AWS account where the AMI was created

  filter {
    name   = "name"
    values = ["My-Golden-AMI-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "platform"
    values = ["windows"]
  }
}

### Update image_id value with the ID of the latest Golden AMI
resource "aws_launch_template" "my_golden_ami_template" {
  name_prefix            = "Golden-AMI-Launch-Template-"
  image_id               = data.aws_ami.my_golden_ami.id
  instance_type          = t2.micro

  lifecycle {
    create_before_destroy = true
  }
}
```


```bash
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
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RequestCount"
  threshold           = 1000
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"

  dimensions = {
    TargetGroup = count.index == 0 ? "${aws_lb_target_group.app[0].arn}" : ""${aws_lb_target_group.app[1].arn}""
  }
}

``` 
- **More details**:
  - [CloudWatch metrics for your Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html)
  - [CloudWatch statistics definitions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Statistics-definitions.html)

## Author:

- [@JManzur](https://jmanzur.com)

## Documentation:

- [EXAMPLE](URL)