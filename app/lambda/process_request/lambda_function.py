import json
import boto3

def lambda_handler(event, context):
    if "body" in event:
        message=json.loads(event['body'])
    else:
        message=event

    # Save message in a local file
    filename=event['requestContext']['requestId']+'.json'
    file='/tmp/'+filename
    with open(file, 'w') as outfile:
        json.dump(message, outfile)

    # Save the file in S3
    s3 = boto3.client('s3')
    try:
        s3.upload_file(file,"devopssquad-results", filename)
    except Exception as e:
        print(e)
        raise e

    return {
        'statusCode': 200,
        'headers': {
            "Access-Control-Allow-Origin": "*"
        },
        'body': json.dumps(message)
    }
