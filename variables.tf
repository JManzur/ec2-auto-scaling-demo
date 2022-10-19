# AWS Region: North of Virginia
variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

# SSH Key-Pair 
variable "key_name" {
  type = string
}

#Use: tags = { Name = "${var.name_prefix}-lambda" }
variable "name_prefix" {
  type = string
}

#EC2 Instance type
#Use: instance_type = var.instance_type["type1"]
variable "instance_type" {
  type = map(string)
  default = {
    "type1" = "t2.micro"
    "type2" = "t2.small"
    "type3" = "t2.medium"
  }
}

variable "demo_app" {
  type = map(any)
  default = {
    "name"        = "load-balancing-demo-app",
    "port"        = 8882,
    "healthcheck" = "/status"
  }
}

/* Tags Variables */
#Use: tags = merge(var.project-tags, { Name = "${var.resource-name-tag}-place-holder" }, )
variable "project-tags" {
  type = map(string)
  default = {
    service     = "Demo EC2 Auto Scaling",
    environment = "POC",
    DeployedBy  = "JManzur - https://jmanzur.com/"
  }
}

variable "DeployThisModule" {
  description = "If set to false, the module will not be deployed"
  type        = bool
  default     = false
}