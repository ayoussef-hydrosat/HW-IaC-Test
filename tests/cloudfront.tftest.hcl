run "cloudfront_https_policy" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_cloudfront_distribution.frontend.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "CloudFront frontend must enforce HTTPS"
  }

  assert {
    condition     = aws_cloudfront_distribution.backoffice.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "CloudFront backoffice must enforce HTTPS"
  }
}

run "cloudfront_oac_required" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_cloudfront_origin_access_control.oac.name != ""
    error_message = "CloudFront must define an Origin Access Control"
  }

  assert {
    condition     = length(aws_cloudfront_distribution.frontend.origin) > 0
    error_message = "CloudFront frontend must define at least one origin"
  }

  assert {
    condition     = length(aws_cloudfront_distribution.backoffice.origin) > 0
    error_message = "CloudFront backoffice must define at least one origin"
  }
}
