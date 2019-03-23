#!/bin/bash
BUCKET=hello.devopssquad.com

aws s3 rm s3://$BUCKET/ --recursive
aws s3 sync app/web/ s3://$BUCKET/

cd app/lambda/process_request
zip -r ../process_request.zip .
