resource "aws_route53_zone" "eon" {
  name = "eon.llc"
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.eon_website.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.eon_website.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.eon.id}"
  records = ["${aws_acm_certificate.eon_website.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_route53_record" "website" {
  zone_id = "${aws_route53_zone.eon.zone_id}"
  name    = "eon.llc"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.production-bucket-eon.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.production-bucket-eon.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "github_verification" {
  name    = "_github-challenge-eon-llc.eon.llc."
  ttl     = 30
  type    = "TXT"
  zone_id = "${aws_route53_zone.eon.zone_id}"

  records = ["b395afeb96"]
}

resource "aws_route53_record" "gmail_mx" {
  name    = "goact.app"
  type    = "MX"
  ttl     = 3600
  records = ["1 ASPMX.L.GOOGLE.COM.", "5 ALT2.ASPMX.L.GOOGLE.COM.", "5 ALT1.ASPMX.L.GOOGLE.COM.", "10 ALT3.ASPMX.L.GOOGLE.COM.", "10 ALT4.ASPMX.L.GOOGLE.COM."]
  zone_id = "${aws_route53_zone.eon.zone_id}"
}
