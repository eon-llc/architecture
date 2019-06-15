resource "aws_route53_zone" "eon" {
  name = "eon.llc"
}

resource "aws_route53_record" "eon_website" {
  zone_id = "${aws_route53_zone.eon.zone_id}"
  name    = "eon.llc"
  type    = "A"
  ttl     = 3600
  records = ["${aws_instance.eon_website.public_ip}"]
}
