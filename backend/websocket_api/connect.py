import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["CONNECTIONS_TABLE"])

def lambda_handler(event, context):
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    user_id = claims["sub"]
    connection_id = event["requestContext"]["connectionId"]

    table.put_item(Item={
        "userId": user_id,
        "connectionId": connection_id
    })

    return {"statusCode": 200, "body": "Connected!"}
