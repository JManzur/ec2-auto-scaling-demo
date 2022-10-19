output "alb_dns" {
  value       = module.asg.alb_dns
  description = "The Demo APP ALB FQDN"
}