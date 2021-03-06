data "archive_file" "github_lambda_zip" {
  type        = "zip"
  source_file = "lambdas/github_stats/index.js"
  output_path = "lambdas/github_stats.zip"
}

resource "aws_lambda_function" "github_stats" {
  function_name = "github_stats"
  handler       = "index.handler"
  runtime       = "nodejs10.x"
  description   = "Github API analyzer"
  role          = "${aws_iam_role.lambda.arn}"
  filename      = "lambdas/github_stats.zip"

  source_code_hash = "${data.archive_file.github_lambda_zip.output_base64sha256}"
}

resource "aws_lambda_permission" "github_lambda" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.github_stats.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.eon.execution_arn}/*/*"
}

data "archive_file" "blog_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/blog_stats/"
  output_path = "lambdas/blog_stats.zip"
}

resource "aws_lambda_function" "blog_stats" {
  function_name = "blog_stats"
  handler       = "index.handler"
  runtime       = "nodejs10.x"
  description   = "Blog publications analyzer"
  role          = "${aws_iam_role.lambda.arn}"
  filename      = "lambdas/blog_stats.zip"

  source_code_hash = "${data.archive_file.blog_lambda_zip.output_base64sha256}"
}

resource "aws_lambda_permission" "blog_lambda" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.blog_stats.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.eon.execution_arn}/*/*"
}

data "archive_file" "bp_jsons_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/bp_jsons/"
  output_path = "lambdas/bp_jsons.zip"
}

resource "aws_lambda_function" "bp_jsons" {
  function_name = "bp_jsons"
  handler       = "index.handler"
  runtime       = "nodejs10.x"
  timeout       = 5
  description   = "Fetch bp.json of all producers"
  role          = "${aws_iam_role.lambda.arn}"
  filename      = "lambdas/bp_jsons.zip"

  source_code_hash = "${data.archive_file.bp_jsons_lambda_zip.output_base64sha256}"
}

resource "aws_lambda_permission" "bp_jsons_lambda" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.bp_jsons.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.eon.execution_arn}/*/*"
}
