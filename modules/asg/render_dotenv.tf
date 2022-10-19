data "template_file" "dotenv" {
  template = file("${path.module}/scripts/dotenv.tpl")

  vars = {
    AWS_REGION   = var.aws_region
    AWS_PROFILE  = var.aws_profile
    ALB_ARN      = aws_lb.app.arn
    Listener_ARN = aws_lb_listener.app.arn
    Farm1_ARN    = aws_lb_target_group.app[0].arn
    Farm2_ARN    = aws_lb_target_group.app[1].arn
    ALB_FQDN     = lower("http://${aws_lb.app.dns_name}:${var.demo_app["port"]}/status")
  }

  depends_on = [
    aws_lb.app,
    aws_lb_listener.app,
    aws_autoscaling_group.app
  ]
}

# Render the template and save the new file:
resource "local_file" "render_dotenv" {
  content  = data.template_file.dotenv.rendered
  filename = "${path.module}/scripts/.env"
}