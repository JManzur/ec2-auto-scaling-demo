module "vpc" {
  source      = "./modules/vpc"
  name_prefix = var.name_prefix
  aws_region  = var.aws_region
}

module "asg" {
  source         = "./modules/asg"
  name_prefix    = var.name_prefix
  aws_region     = var.aws_region
  aws_profile    = var.aws_profile
  vpc_id         = module.vpc.vpc_id
  public_subnet  = module.vpc.public_subnet
  private_subnet = module.vpc.private_subnet
  key_name       = var.key_name
  demo_app       = var.demo_app
  instance_type  = var.instance_type
}

module "bastion" {
  source        = "./modules/bastion"
  count         = var.DeployThisModule ? 1 : 0
  name_prefix   = var.name_prefix
  aws_region    = var.aws_region
  vpc_id        = module.vpc.vpc_id
  public_subnet = module.vpc.public_subnet
  key_name      = var.key_name
  instance_type = var.instance_type
}