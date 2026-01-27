run "alb_https_listener" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_lb_listener.https.protocol == "HTTPS"
    error_message = "ALB must have an HTTPS listener"
  }

  assert {
    condition     = aws_lb.main.load_balancer_type == "application"
    error_message = "ALB must be application type"
  }

  assert {
    condition     = aws_lb.main.internal == false
    error_message = "ALB must be internet-facing"
  }

  assert {
    condition     = aws_lb_target_group.api.target_type == "ip"
    error_message = "ALB target group must use ip targets"
  }
}

run "alb_http_redirect" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "redirect"
    error_message = "HTTP listener must redirect to HTTPS"
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].redirect[0].protocol == "HTTPS"
    error_message = "HTTP redirect must use HTTPS"
  }
}
