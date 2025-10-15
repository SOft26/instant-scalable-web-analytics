# Route53 hosted zone
resource "aws_route53_zone" "main" {
  name         = "analyzr.pro"
}

# ACM certificate for my domain
resource "aws_acm_certificate" "cert" {
  domain_name       = "analyzr.pro"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records (safe for sets)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ALB (created by AWS Load Balancer Controller in Kubernetes)
# Do not define subnets or listeners here
  # Just import:
  # terraform import aws_lb.plausible <alb-arn> if you want terraform to manage, create a resource block, i created a data source to reference only
data "aws_lb" "plausible" {
  name = "k8s-plausiblegroup-09ea225b23"
}

# Fetch the ALB managed SG
data "aws_security_group" "alb_managed" {
  filter {
    name   = "group-name"
    values = ["k8s-plausiblegroup-bd51f12c76"] # the ALB managed SG name
  }
}

# Fetch the backend SG (shared with nodes/pods)
data "aws_security_group" "backend" {
  filter {
    name   = "group-name"
    values = ["k8s-traffic-plausibleeks-23367c0085"] # replace with your backend SG name
  }
}


resource "aws_security_group_rule" "alb_to_backend" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"

  security_group_id        = data.aws_security_group.backend.id   # backend SG (target)
  source_security_group_id = data.aws_security_group.alb_managed.id  # ALB SG (source)
}





# Route53 record mapping analyzr.pro → ALB
resource "aws_route53_record" "plausible" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "analyzr.pro"
  type    = "A"

  alias {
    name                   = data.aws_lb.plausible.dns_name
    zone_id                = data.aws_lb.plausible.zone_id
    evaluate_target_health = true
  }
}
