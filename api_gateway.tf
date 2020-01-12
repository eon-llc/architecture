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

resource "aws_api_gateway_resource" "blog" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  parent_id   = "${aws_api_gateway_rest_api.eon.root_resource_id}"
  path_part   = "blog"
}

resource "aws_api_gateway_resource" "bp_jsons" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  parent_id   = "${aws_api_gateway_rest_api.eon.root_resource_id}"
  path_part   = "bp_jsons"
}

# --------------------------------------------------
# OPTIONS method, for fetching GitHub stats
# required by AWS to enable CORS
# https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html
# --------------------------------------------------
resource "aws_api_gateway_method" "github_options" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.github.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "github_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github_options.http_method}"
  depends_on  = ["aws_api_gateway_method.github_options"]
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

resource "aws_api_gateway_integration" "github_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github_options.http_method}"
  type        = "MOCK"
  depends_on  = ["aws_api_gateway_method.github_options"]

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "github_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github_options.http_method}"
  status_code = "${aws_api_gateway_method_response.github_options.status_code}"
  depends_on  = ["aws_api_gateway_method_response.github_options"]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# GET method, for fetching GitHub stats
# --------------------------------------------------
resource "aws_api_gateway_method" "github_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.github.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "github_get" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github_get.http_method}"
  status_code = "200"
  depends_on  = ["aws_api_gateway_method.github_get"]

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration" "github_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_method.github_get.resource_id}"
  http_method = "${aws_api_gateway_method.github_get.http_method}"
  depends_on  = ["aws_api_gateway_method.github_get", "aws_lambda_function.github_stats"]

  integration_http_method = "POST"

  type = "AWS"
  uri  = "${aws_lambda_function.github_stats.invoke_arn}"

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "github_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.github.id}"
  http_method = "${aws_api_gateway_method.github_get.http_method}"
  depends_on  = ["aws_api_gateway_integration.github_lambda"]
  status_code = "${aws_api_gateway_method_response.github_get.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# OPTIONS method, for fetching Blog stats
# required by AWS to enable CORS
# https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html
# --------------------------------------------------
resource "aws_api_gateway_method" "blog_options" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.blog.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "blog_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.blog.id}"
  http_method = "${aws_api_gateway_method.blog_options.http_method}"
  depends_on  = ["aws_api_gateway_method.blog_options"]
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

resource "aws_api_gateway_integration" "blog_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.blog.id}"
  http_method = "${aws_api_gateway_method.blog_options.http_method}"
  type        = "MOCK"
  depends_on  = ["aws_api_gateway_method.blog_options"]

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "blog_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.blog.id}"
  http_method = "${aws_api_gateway_method.blog_options.http_method}"
  status_code = "${aws_api_gateway_method_response.blog_options.status_code}"
  depends_on  = ["aws_api_gateway_method_response.blog_options"]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# GET method, for fetching Blog stats
# --------------------------------------------------
resource "aws_api_gateway_method" "blog_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.blog.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "blog_get" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.blog.id}"
  http_method = "${aws_api_gateway_method.blog_get.http_method}"
  status_code = "200"
  depends_on  = ["aws_api_gateway_method.blog_get"]

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration" "blog_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_method.blog_get.resource_id}"
  http_method = "${aws_api_gateway_method.blog_get.http_method}"
  depends_on  = ["aws_api_gateway_method.blog_get", "aws_lambda_function.blog_stats"]

  integration_http_method = "POST"

  type = "AWS"
  uri  = "${aws_lambda_function.blog_stats.invoke_arn}"

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "blog_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.blog.id}"
  http_method = "${aws_api_gateway_method.blog_get.http_method}"
  depends_on  = ["aws_api_gateway_integration.blog_lambda"]
  status_code = "${aws_api_gateway_method_response.blog_get.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# OPTIONS method, for fetching BP.json files
# required by AWS to enable CORS
# https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html
# --------------------------------------------------
resource "aws_api_gateway_method" "bp_jsons_options" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "bp_jsons_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method = "${aws_api_gateway_method.bp_jsons_options.http_method}"
  depends_on  = ["aws_api_gateway_method.bp_jsons_options"]
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

resource "aws_api_gateway_integration" "bp_jsons_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method = "${aws_api_gateway_method.bp_jsons_options.http_method}"
  type        = "MOCK"
  depends_on  = ["aws_api_gateway_method.bp_jsons_options"]

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "bp_jsons_options" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method = "${aws_api_gateway_method.bp_jsons_options.http_method}"
  status_code = "${aws_api_gateway_method_response.bp_jsons_options.status_code}"
  depends_on  = ["aws_api_gateway_method_response.bp_jsons_options"]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# GET method, for fetching BP.json files
# --------------------------------------------------
resource "aws_api_gateway_method" "bp_jsons_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.eon.id}"
  resource_id   = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "bp_jsons_get" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method = "${aws_api_gateway_method.bp_jsons_get.http_method}"
  status_code = "200"
  depends_on  = ["aws_api_gateway_method.bp_jsons_get"]

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration" "bp_jsons_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_method.bp_jsons_get.resource_id}"
  http_method = "${aws_api_gateway_method.bp_jsons_get.http_method}"
  depends_on  = ["aws_api_gateway_method.bp_jsons_get", "aws_lambda_function.bp_jsons"]

  integration_http_method = "POST"

  type = "AWS"
  uri  = "${aws_lambda_function.bp_jsons.invoke_arn}"

  request_templates {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "bp_jsons_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  resource_id = "${aws_api_gateway_resource.bp_jsons.id}"
  http_method = "${aws_api_gateway_method.bp_jsons_get.http_method}"
  depends_on  = ["aws_api_gateway_integration.bp_jsons_lambda"]
  status_code = "${aws_api_gateway_method_response.bp_jsons_get.status_code}"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# --------------------------------------------------
# DEPLOYMENT
# --------------------------------------------------
resource "aws_api_gateway_stage" "v1" {
  stage_name            = "v1"
  rest_api_id           = "${aws_api_gateway_rest_api.eon.id}"
  deployment_id         = "${aws_api_gateway_deployment.eon.id}"
  cache_cluster_enabled = true
  cache_cluster_size    = 0.5
}

resource "aws_api_gateway_method_settings" "v1" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"
  stage_name  = "${aws_api_gateway_stage.v1.stage_name}"
  method_path = "*/*"

  settings {
    caching_enabled      = true
    cache_ttl_in_seconds = 3600
  }
}

resource "aws_api_gateway_deployment" "eon" {
  rest_api_id = "${aws_api_gateway_rest_api.eon.id}"

  depends_on = [
    "aws_api_gateway_integration.github_lambda",
    "aws_api_gateway_integration.blog_lambda",
    "aws_api_gateway_integration.bp_jsons_lambda",
    "aws_api_gateway_integration_response.github_lambda",
    "aws_api_gateway_integration_response.blog_lambda",
    "aws_api_gateway_integration_response.bp_jsons_lambda",
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

resource "aws_api_gateway_domain_name" "eon" {
  certificate_arn = "${aws_acm_certificate.eon_website.arn}"
  domain_name     = "api.eon.llc"
}

resource "aws_api_gateway_base_path_mapping" "eon" {
  api_id      = "${aws_api_gateway_rest_api.eon.id}"
  domain_name = "${aws_api_gateway_domain_name.eon.domain_name}"
}
