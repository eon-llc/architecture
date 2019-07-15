resource "aws_api_gateway_rest_api" "eon" {
  name        = "eon"
  description = "API for eon's website"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "github" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  parent_id   = "${aws_api_gateway_rest_api.eon.root_resource_id}"
  path_part   = "github"
}

resource "aws_api_gateway_method" "github" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.github.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_method.github.resource_id}"
  http_method = "${aws_api_gateway_method.github.http_method}"

  integration_http_method = "POST"

  type = "AWS"
  uri  = "${aws_lambda_function.github_stats.invoke_arn}"
}

resource "aws_api_gateway_method_response" "github" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github.http_method}"

  status_code = "${aws_api_gateway_method_response.github.status_code}"

  depends_on = [
    "aws_api_gateway_integration.lambda",
  ]
}

resource "aws_api_gateway_stage" "github" {
  stage_name            = "v1"
  rest_api_id           = "${aws_api_gateway_rest_api.eon.id}"
  deployment_id         = "${aws_api_gateway_deployment.github.id}"
  cache_cluster_enabled = true
  cache_cluster_size    = 0.5
}

resource "aws_api_gateway_method_settings" "github" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  stage_name  = "${aws_api_gateway_stage.github.stage_name}"
  method_path = "${aws_api_gateway_resource.github.path_part}/${aws_api_gateway_method.github.http_method}"

  settings {
    caching_enabled      = true
    cache_ttl_in_seconds = 3600
  }
}

resource "aws_api_gateway_deployment" "github" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"

  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration_response.lambda",
  ]
}
