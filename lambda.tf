data "archive_file" "github_lambda_zip" {
  type        = "zip"
  source_file = "lambdas/github_stats/index.js"
  output_path = "lambdas/github_stats/github_stats.zip"
}

resource "aws_lambda_function" "github_stats" {
  function_name = "github_stats"
  handler       = "index.handler"
  runtime       = "nodejs10.x"
  description   = "Github API analyzer"
  role          = "${aws_iam_role.lambda.arn}"
  filename      = "lambdas/github_stats/github_stats.zip"

  source_code_hash = "${data.archive_file.github_lambda_zip.output_base64sha256}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.github_stats.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.eon.execution_arn}/*/*"
}
