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

resource "aws_api_gateway_method_response" "method_response_200" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.resource.id}"
    http_method   = "${aws_api_gateway_method.method.http_method}"
    status_code   = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
        "method.response.header.Access-Control-Allow-Headers" = true
        "method.response.header.Access-Control-Allow-Methods" = true

    }
    depends_on = ["aws_api_gateway_method.method"]
}
##
resource "aws_api_gateway_method" "options_method" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.resource.id}"
    http_method   = "OPTIONS"
    authorization = "NONE"
}
resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.resource.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    status_code   = "200"
    response_models {
        "application/json" = "Empty"
    }
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = false,
        "method.response.header.Access-Control-Allow-Methods" = false,
        "method.response.header.Access-Control-Allow-Origin" = false
    }
    depends_on = ["aws_api_gateway_method.options_method"]
}
resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.resource.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    type          = "MOCK"

    request_templates = {
      "application/json" = "{\"statusCode\": 200}"
    }

    depends_on = ["aws_api_gateway_method.options_method"]
}
resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
    resource_id   = "${aws_api_gateway_resource.resource.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    status_code   = "${aws_api_gateway_method_response.options_200.status_code}"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }

    depends_on = ["aws_api_gateway_method_response.options_200"]
}
##
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

  depends_on = ["aws_api_gateway_method.method"]
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

resource "aws_iam_policy" "policy" {
    name = "lambda-policy"
    description = "Lambda policy"
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Sid": "Write",
      "Effect": "Allow",
      "Action": [
        "s3:Put*"
      ],
      "Resource": "arn:aws:s3:::${var.website_bucket_name}/results/*"
    }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "role" {
    name = "policy-attachment"
    policy_arn = "${aws_iam_policy.policy.arn}"
    roles = ["${aws_iam_role.role.name}"]
}


# Deployment of Method
resource "aws_api_gateway_deployment" "instance" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${var.api_stage_name}"

  variables {
    deployed_at = "${var.deployed_at}"
  }
  depends_on = ["aws_api_gateway_method.method", "aws_api_gateway_integration.integration"]
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

# Enable a Custom Domain in API Gateway
resource "aws_api_gateway_domain_name" "customdomain" {
  domain_name              = "${var.api_domain}"
  regional_certificate_arn = "${var.regional_acm_arm}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${aws_api_gateway_deployment.instance.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.customdomain.domain_name}"
}

# Add the API Gateway Custom domain DNS record
data "aws_route53_zone" "api" {
  name    = "${var.parent_zone_name}"
}

resource "aws_route53_record" "api" {
  name    = "${aws_api_gateway_domain_name.customdomain.domain_name}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.api.zone_id}"

  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.customdomain.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.customdomain.regional_zone_id}"
  }
}
