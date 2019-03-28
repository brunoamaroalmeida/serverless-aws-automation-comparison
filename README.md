# serverless-aws-automation-comparison
A Comparison between different deployment automation tools for an AWS Serverless project

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
