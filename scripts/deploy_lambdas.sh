#!/bin/bash
set -e

# === Config ===
BUCKET_NAME="talkbridge-lambda-artifacts"  
REGION="us-east-1"
LAMBDA_DIR="../backend/websocket_api"      

# === Ensure S3 bucket exists ===
if ! aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
  echo "Creating S3 bucket: $BUCKET_NAME"
  aws s3 mb "s3://$BUCKET_NAME" --region $REGION
fi

# === Function list ===
FUNCTIONS=("connect" "disconnect" "send_message")

for fn in "${FUNCTIONS[@]}"; do
  echo "📦 Zipping $fn.py ..."
  cd $LAMBDA_DIR
  zip -r9 "${fn}.zip" "${fn}.py" > /dev/null
  cd - > /dev/null

  echo "⬆️ Uploading ${fn}.zip to S3..."
  aws s3 cp "${LAMBDA_DIR}/${fn}.zip" "s3://${BUCKET_NAME}/${fn}.zip"

  echo "🧹 Cleaning up local ${fn}.zip ..."
  rm -f "${LAMBDA_DIR}/${fn}.zip"
done

echo "✅ All websocket Lambdas deployed to s3://${BUCKET_NAME}/ and local .zip files removed"
