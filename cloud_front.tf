resource "aws_cloudfront_distribution" "production-bucket-eon" {
  origin {
    domain_name = "${aws_s3_bucket.eon_llc_production.bucket_regional_domain_name}"
    origin_id   = "S3-${aws_s3_bucket.eon_llc_production.bucket}"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  aliases             = ["eon.llc"]
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Eon website"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.eon_llc_production.bucket}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
  }

  custom_error_response {
    error_caching_min_ttl = 5
    error_code            = 404
    response_page_path    = "/index.html"
    response_code         = 200
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.eon_website.arn}"
    ssl_support_method  = "sni-only"
  }

  tags {
    Environment = "production"
  }
}

resource "aws_cloudfront_distribution" "rem_full_node_api" {
  origin {
    domain_name = "${aws_instance.rem_full_node.public_dns}"
    origin_id   = "${aws_instance.rem_full_node.id}"

    custom_origin_config {
      origin_protocol_policy = "match-viewer"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  aliases         = ["rem.eon.llc"]
  enabled         = true
  is_ipv6_enabled = false
  comment         = "REM API"
  price_class     = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["HEAD", "GET", "OPTIONS"]
    target_origin_id = "${aws_instance.rem_full_node.id}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.eon_website.arn}"
    ssl_support_method  = "sni-only"
  }

  tags {
    Environment = "production"
  }
}
