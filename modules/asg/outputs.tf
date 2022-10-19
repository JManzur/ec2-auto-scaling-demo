output "alb_dns" {
  value = lower("http://${aws_lb.app.dns_name}:${var.demo_app["port"]}")
}