run "acm_dns_validation" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }

  assert {
    condition     = aws_acm_certificate.main.validation_method == "DNS"
    error_message = "ACM cert must use DNS validation"
  }

  assert {
    condition     = aws_acm_certificate.cloudfront.validation_method == "DNS"
    error_message = "CloudFront ACM cert must use DNS validation"
  }
}

run "route53_records" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }

  assert {
    condition     = aws_route53_zone.main.name != ""
    error_message = "Route53 zone must have a name"
  }

  assert {
    condition     = aws_route53_record.api.type == "A"
    error_message = "Route53 api record must be an A record"
  }

  assert {
    condition     = aws_route53_record.frontend.type == "A"
    error_message = "Route53 frontend record must be an A record"
  }
}
