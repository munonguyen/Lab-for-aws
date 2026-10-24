#!/bin/bash
# Helper script to connect to any Lab 92 EC2 instance via AWS SSM Session Manager
TARGET="${1:-dev}"
REGION="us-east-1"

case "$TARGET" in
  dev|np1)   TAG="lab92-ec2-dev" ;;
  test|np2)  TAG="lab92-ec2-test" ;;
  prod|p1)   TAG="lab92-ec2-prod" ;;
  dcs|shared)TAG="lab92-ec2-dcs" ;;
  dc)        TAG="lab92-ec2-dc" ;;
  *)         TAG="$TARGET" ;;
esac

echo "🔍 Đang tìm máy ảo với tag Name=$TAG tại $REGION..."
INSTANCE_ID=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo "❌ Lỗi: Không tìm thấy máy ảo đang chạy với tag Name=$TAG!"
  exit 1
fi

echo "🚀 Đang mở phiên làm việc trực tiếp vào $TAG ($INSTANCE_ID)..."
aws ssm start-session --target "$INSTANCE_ID" --region "$REGION"
