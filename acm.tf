resource "aws_acm_certificate" "eon_website" {
  domain_name       = "eon.llc"
  validation_method = "DNS"

  tags = {
    Environment = "Production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.eon_website.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
