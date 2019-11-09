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

resource "aws_route53_record" "eon_api" {
  name    = "${aws_api_gateway_domain_name.eon.domain_name}"
  zone_id = "${aws_route53_zone.eon.id}"
  type    = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.eon.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.eon.cloudfront_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "rem_full_node_api" {
  zone_id = "${aws_route53_zone.eon.zone_id}"
  name    = "rem.eon.llc"
  type    = "A"
  ttl     = "300"

  records = ["${aws_eip.rem_full_node.public_ip}"]
}

resource "aws_route53_record" "rem_producer_node_p2p" {
  zone_id = "${aws_route53_zone.eon.zone_id}"
  name    = "p2p.testnet.rem.eon.llc"
  type    = "A"
  ttl     = "300"

  records = ["${aws_eip.rem_producing_node.public_ip}"]
}

resource "aws_route53_record" "github_verification" {
  name    = "_github-challenge-eon-llc.eon.llc."
  ttl     = 300
  type    = "TXT"
  zone_id = "${aws_route53_zone.eon.zone_id}"

  records = ["b395afeb96"]
}

resource "aws_route53_record" "gmail_mx" {
  name    = "eon.llc"
  type    = "MX"
  ttl     = 3600
  records = ["1 ASPMX.L.GOOGLE.COM.", "5 ALT2.ASPMX.L.GOOGLE.COM.", "5 ALT1.ASPMX.L.GOOGLE.COM.", "10 ALT3.ASPMX.L.GOOGLE.COM.", "10 ALT4.ASPMX.L.GOOGLE.COM."]
  zone_id = "${aws_route53_zone.eon.zone_id}"
}
