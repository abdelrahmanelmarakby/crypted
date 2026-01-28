#!/bin/bash

# Deploy Cloud Tasks Queues for Crypted Firebase Functions

set -e

PROJECT_ID="crypted-8468f"
LOCATION="us-central1"

echo "=================================="
echo "Cloud Tasks Queue Deployment"
echo "=================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    exit 1
fi

# Set project
gcloud config set project $PROJECT_ID

echo "Creating Cloud Tasks queues in region: $LOCATION"
echo ""

# Create Notification Queue
echo "Creating notification-queue..."
gcloud tasks queues create notification-queue \
  --location=$LOCATION \
  --max-concurrent-dispatches=100 \
  --max-dispatches-per-second=50 \
  --max-attempts=5 \
  --max-retry-duration=3600s \
  --min-backoff=5s \
  --max-backoff=300s \
  --max-doublings=5 \
  2>/dev/null || echo "✓ notification-queue already exists"

echo ""

# Create Analytics Queue
echo "Creating analytics-queue..."
gcloud tasks queues create analytics-queue \
  --location=$LOCATION \
  --max-concurrent-dispatches=10 \
  --max-dispatches-per-second=5 \
  --max-attempts=3 \
  --max-retry-duration=7200s \
  --min-backoff=10s \
  --max-backoff=600s \
  --max-doublings=4 \
  2>/dev/null || echo "✓ analytics-queue already exists"

echo ""

# Create Cleanup Queue
echo "Creating cleanup-queue..."
gcloud tasks queues create cleanup-queue \
  --location=$LOCATION \
  --max-concurrent-dispatches=5 \
  --max-dispatches-per-second=1 \
  --max-attempts=3 \
  --max-retry-duration=3600s \
  --min-backoff=30s \
  --max-backoff=1800s \
  --max-doublings=3 \
  2>/dev/null || echo "✓ cleanup-queue already exists"

echo ""
echo "=================================="
echo "✅ Queue Deployment Complete!"
echo "=================================="
echo ""

# List all queues
echo "Active queues:"
gcloud tasks queues list --location=$LOCATION

echo ""
echo "Next Steps:"
echo "1. Deploy Cloud Functions that process tasks"
echo "2. Update existing functions to enqueue tasks"
echo "3. Monitor queue performance in Cloud Console"
echo ""
echo "Queue URLs:"
echo "https://console.cloud.google.com/cloudtasks?project=$PROJECT_ID"
echo ""
