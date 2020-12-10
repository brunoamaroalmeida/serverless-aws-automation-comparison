#!/bin/bash
WEBSITE_BUCKET=hello.devopssquad.com
RESULTS_BUCKET=devopssquad-results
#OPS_BUCKET=serverless-aws-automation-comparison

aws s3 rm s3://$WEBSITE_BUCKET/ --recursive
#aws s3 rm s3://$OPS_BUCKET/ --recursive
aws s3 rm s3://$RESULTS_BUCKET/ --recursive
