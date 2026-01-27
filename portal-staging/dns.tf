resource "aws_route53_zone" "main" {
  name = local.domain_name
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${local.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "main" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "api.${local.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = local.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "admin.${local.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  cert_validation_records = var.enable_cert_validation_records ? concat(
    [for idx, dvo in tolist(aws_acm_certificate.main.domain_validation_options) : {
      key    = "${dvo.domain_name}-main"
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }],
    [for idx, dvo in tolist(aws_acm_certificate.cloudfront.domain_validation_options) : {
      key    = "${dvo.domain_name}-cloudfront"
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }]
  ) : []
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in local.cert_validation_records : dvo.key => dvo
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  depends_on              = [aws_route53_record.cert_validation]
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "bastion.${local.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.public_ip]
}

resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "backoffice" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "admin.${local.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.backoffice.domain_name
    zone_id                = aws_cloudfront_distribution.backoffice.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alloy_otlp" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "alloy-otlp.${local.domain_name}"
  type    = "A"

  alias {
    name                   = var.alloy_otlp_host
    zone_id                = var.alloy_otlp_lb_zone_id
    evaluate_target_health = false
  }
}

output "nameservers" {
  value       = aws_route53_zone.main.name_servers
  description = "Nameservers for the subdomain. Add these to Cloudflare."
}

resource "aws_route53_record" "smtp_mx_record" {
  name = "${local.domain_name}."
  type = "MX"
  ttl  = 1800
  records = [
    "10 inbound-smtp.us-east-2.amazonaws.com"
  ]
  zone_id = aws_route53_zone.main.zone_id
}


resource "aws_route53_record" "dmarc_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${local.domain_name}"
  type    = "TXT"
  ttl     = 300

  records = [
    "v=DMARC1;p=quarantine;rua=mailto:my_dmarc_report@irriwatch.hydrosat.com"
  ]
}
