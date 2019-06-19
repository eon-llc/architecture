resource "aws_ecr_repository" "eon_website_build" {
  name = "eon/website_build"
}

resource "aws_ecr_repository_policy" "eon_website_build_policy" {
  repository = "${aws_ecr_repository.eon_website_build.name}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "CodeBuildAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "ecr:*"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "eon_website_build_policy" {
  repository = "${aws_ecr_repository.eon_website_build.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 2 images",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 2
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
