# serverless-aws-automation-comparison

A practical comparison between different deployment automation tools for an AWS Serverless project.

This project is meant to be used as reference for learning purposes only. It was presented in the [AWS Community Summit UK 2019](https://comsum.co.uk/comsum-manchester/) by [Bruno Amaro Almeida](https://www.brunoamaro.com).

Currently supported:

* Cloudformation
* SAM
* Terraform

# Pre-requisites

In order to try out each deployment methods, please make sure you have the following:

* AWS Account
* aws client tool installed and configured to your account
* terraform client tool installed
* sam client tool installed
* A Public Domain in AWS Route 53
* A Regional SSL Certificate in AWS Certificate Manager


# Example Serverless App

To make a comparison we need an example application to compare with. Our example serverless app is
a static website (in S3) that allows the visitor to select an option.
![Website](docs/website.png?raw=true "Website")


There is an API that receives the option the user submitted (API Gateway) and processes it (Lambda) by storing the result in persistent storage (S3).

We allow the Developer to do Analytics over the results by using a combination of Athena with QuickSight.
![Athena+QuickSight](docs/athena_quicksight.png?raw=true "Athena+QuickSight")


## Architecture

![Architecture](docs/Architecture_Serverless_App.png?raw=true "Architecture")


## Terraform

### Infrastructure & App Deployment
#### Requirements
aws cli and terraform installed and configured

> Please remember to adapt the S3 bucket names and Route 53 custom domains to your own enviroment.

Set the enviroment settings
```
export AWS_DEFAULT_REGION="eu-west-1"
export TF_VAR_deployed_at=$(date +%s)
```

Deploy apps (at this stage only lambda)
```
./deploy_apps.sh
```

Deploy infrastructure
```
cd infra/terraform
terraform init
terraform plan
terraform apply
```

Deploy apps (lambda + website)
```
cd ../../
./deploy_apps.sh
```

(Optional) Generate resource graph
```
terraform graph | dot -Tsvg > graph.svg
```
![Terraform Graph](docs/terraform_graph.svg?raw=true "Terraform Graph")


### Infrastructure & App Cleanup

This will terminate any resources that were created
```
cd infra/terraform
terraform destroy
```



## Athena (Optional)

Create a table based on the S3 Result Location
```
CREATE EXTERNAL TABLE IF NOT EXISTS default.devopssquad_results (
  `option` string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1'
) LOCATION 's3://devopssquad-results/'
TBLPROPERTIES ('has_encrypted_data'='true');
```

Query the results - count votes and group them by option
```
SELECT option, count(option) as sum FROM "default"."devopssquad_results" group by option;
```

## QuickSight (Optional)

You can create a QuickSight dashboard using Athena as source. Simply drag and drop the fields you need and customize the graph.

## Embebbed QuickSight (Optional x2)

If you want to share your QuickSight dashboard to the public, please take a look at the file app/web/result.html and follow the instructions in this example: [https://github.com/aws-samples/amazon-quicksight-embedding-sample]

To confirm the Cognito user, you can use commands similar to the ones below (adapt to your values):

```
aws cognito-idp admin-initiate-auth --user-pool-id  eu-west-1_OTyJTR6aE --client-id 6cjqnmq08fosuvde6tnvtbfsqj --auth-flow ADMIN_NO_SRP_AUTH --auth-parameters USERNAME=guest,PASSWORD='Guest!123'

aws cognito-idp admin-confirm-sign-up --user-pool-id  eu-west-1_OTyJTR6aE --username guest
```


# Credits

This work was developed by [Bruno Amaro Almeida](https://www.brunoamaro.com).

Projects that were used and help during this comparison:

[https://github.com/ringods/terraform-website-s3-cloudfront-route53/]



# TODO

* Add Serverless Framework to the comparison
* Enable SSL in the static website by using CloudFront
* Athena templates
* Quicksight templates
* Cognito templates
