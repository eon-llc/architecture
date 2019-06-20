resource "aws_codebuild_project" "eon_website_prod" {
  name          = "eon_website_prod"
  description   = "Eon website production"
  build_timeout = "5"
  service_role  = "${aws_iam_role.build.arn}"

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${aws_ecr_repository.eon_website_build.repository_url}:latest"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "S3_TARGET"
      value = "${aws_s3_bucket.eon_llc_production.bucket}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "build/specs/build_spec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "eon_website_test" {
  name          = "eon_website_test"
  description   = "Eon website test"
  build_timeout = "5"
  service_role  = "${aws_iam_role.build.arn}"

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${aws_ecr_repository.eon_website_test.repository_url}:latest"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "build/specs/test_spec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "website_test_pull_request" {
  name          = "eon_website_test_pull_request"
  description   = "Test on pull request"
  build_timeout = "5"
  service_role  = "${aws_iam_role.eon_pull_request.arn}"

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${aws_ecr_repository.eon_website_test.repository_url}"
    type         = "LINUX_CONTAINER"
  }

  source {
    type                = "GITHUB"
    location            = "https://github.com/eon-llc/website.git"
    git_clone_depth     = 1
    report_build_status = true
    buildspec           = "build/specs/test_spec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

resource "aws_codebuild_webhook" "website_test_pull_request" {
  project_name  = "${aws_codebuild_project.website_test_pull_request.name}"
  branch_filter = "master"
}
