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

# --------------------------------------------------
# OPTIONS method, required by AWS to enable CORS
# https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html
# --------------------------------------------------
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.github.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.options_method.http_method}"
  depends_on  = ["aws_api_gateway_method.options_method"]
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.options_method.http_method}"
  type        = "MOCK"
  depends_on  = ["aws_api_gateway_method.options_method"]

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.options_method.http_method}"
  status_code = "${aws_api_gateway_method_response.options.status_code}"
  depends_on  = ["aws_api_gateway_method_response.options"]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# GET method, for fetching the stats
# --------------------------------------------------
resource "aws_api_gateway_method" "github" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.github.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "github" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github.http_method}"
  status_code = "200"
  depends_on  = ["aws_api_gateway_method.github"]

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_method.github.resource_id}"
  http_method = "${aws_api_gateway_method.github.http_method}"
  depends_on  = ["aws_api_gateway_method.github", "aws_lambda_function.github_stats"]

  integration_http_method = "POST"

  type = "AWS"
  uri  = "${aws_lambda_function.github_stats.invoke_arn}"

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github.http_method}"
  depends_on  = ["aws_api_gateway_integration.lambda"]
  status_code = "${aws_api_gateway_method_response.github.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
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

  // forces a re-deployment
  variables {
    deployed_at = "${timestamp()}"
  }

  // avoids the error of active stages
  // having nothing to point to during delete and creation
  lifecycle {
    create_before_destroy = true
  }
}
