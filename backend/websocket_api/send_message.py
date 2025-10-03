import boto3
import os
import json

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["CONNECTIONS_TABLE"])
apigw = boto3.client("apigatewaymanagementapi",
                     endpoint_url=f"https://{os.environ['WEBSOCKET_API_ID']}.execute-api.{os.environ['AWS_REGION']}.amazonaws.com/dev")

def lambda_handler(event, context):
    body = json.loads(event["body"])
    target_user = body["toUserId"]
    message = body["message"]

    resp = table.get_item(Key={"userId": target_user})
    if "Item" not in resp:
        return {"statusCode": 404, "body": "User not connected"}

    connection_id = resp["Item"]["connectionId"]

    apigw.post_to_connection(
        Data=json.dumps({"from": event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"], "message": message}),
        ConnectionId=connection_id
    )

    return {"statusCode": 200, "body": "Message sent"}

