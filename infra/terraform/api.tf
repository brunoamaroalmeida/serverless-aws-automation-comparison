data "aws_caller_identity" "current" {}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "process_request"
}

# Resource Method
resource "aws_api_gateway_resource" "resource" {
  path_part   = "api"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# API Key
resource "aws_api_gateway_api_key" "apikey" {
  name = "apikey"
  value = "thisismyapikeythisismyapikeythisismyapikey"
}

# Integration for Lambda
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
}

# Deployment of Method
resource "aws_api_gateway_deployment" "instance" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${var.api_stage_name}"

  variables {
    deployed_at = "${var.deployed_at}"
  }
}

# API Key Usage Plan
resource "aws_api_gateway_usage_plan" "apiusageplan" {
  name         = "process-request-usage-plan"
  description  = "Usage Plan for Process Request"
  product_code = "PREQUEST"

  api_stages {
    api_id = "${aws_api_gateway_rest_api.api.id}"
    stage  = "${aws_api_gateway_deployment.instance.stage_name}"
  }

  quota_settings {
    limit  = 10000
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 500
    rate_limit  = 1000
  }
}

# Associate API Key with Usage Plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = "${aws_api_gateway_api_key.apikey.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.apiusageplan.id}"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_lambda_function" "lambda" {
  filename         = "../../app/lambda/process_request.zip"
  function_name    = "process_request"
  role             = "${aws_iam_role.role.arn}"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.7"
  source_code_hash = "${base64sha256(file("../../app/lambda/process_request.zip"))}"
}

# IAM
resource "aws_iam_role" "role" {
  name = "lambdarole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}
