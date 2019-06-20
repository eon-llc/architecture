resource "aws_codepipeline" "eon_website" {
  name     = "eon_website"
  role_arn = "${aws_iam_role.pipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.eon_llc_artifacts.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration {
        Owner      = "eon-llc"
        Repo       = "website"
        Branch     = "master"
        OAuthToken = "${var.github_token}"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name            = "Test"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      version         = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.eon_website_test.name}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code"]
      output_artifacts = ["website"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.eon_website_prod.name}"
      }
    }
  }
}
