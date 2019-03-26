#!/bin/bash
WEBSITE_BUCKET=hello.devopssquad.com
OPS_BUCKET=serverless-aws-automation-comparison

# Upload web app to Website bucket
aws s3 sync app/web/ s3://$WEBSITE_BUCKET/

# Compress Lambda
cd app/lambda/process_request
zip -r  ../../../process_request.zip *
cd ../../../

# Upload lambda to Ops bucket
aws s3 cp process_request.zip s3://$OPS_BUCKET
rm -fr process_request.zip
