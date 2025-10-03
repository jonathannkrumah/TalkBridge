import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["CONNECTIONS_TABLE"])

def lambda_handler(event, context):
    connection_id = event["requestContext"]["connectionId"]

    # delete by scanning (since userId is the PK)
    resp = table.scan(
        FilterExpression="connectionId = :c",
        ExpressionAttributeValues={":c": connection_id}
    )
    for item in resp["Items"]:
        table.delete_item(Key={"userId": item["userId"]})

    return {"statusCode": 200, "body": "Disconnected!"}
