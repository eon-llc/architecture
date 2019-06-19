resource "aws_s3_bucket" "eon_llc_artifacts" {
  bucket = "eon-llc-artifacts"
  acl    = "private"
}

resource "aws_s3_bucket" "eon_llc_production" {
  bucket = "eon-llc-production"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }

  tags {
    Name = "Production"
  }

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForGetBucketObjects",
      "Effect": "Allow",
      "Principal": {
          "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::eon-llc-production/*"
    }
  ]
}
EOF
}
