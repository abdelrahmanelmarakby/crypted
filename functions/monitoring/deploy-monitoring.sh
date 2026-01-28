#!/bin/bash

# Deploy Monitoring Infrastructure for Crypted Firebase Functions
# This script sets up Cloud Monitoring dashboards and alert policies

set -e  # Exit on error

PROJECT_ID="crypted-8468f"
REGION="us-central1"

echo "=================================="
echo "Crypted Monitoring Deployment"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}Error: Not logged into gcloud${NC}"
    echo "Run: gcloud auth login"
    exit 1
fi

# Set project
echo -e "${YELLOW}Setting project to: $PROJECT_ID${NC}"
gcloud config set project $PROJECT_ID

echo ""
echo "=================================="
echo "Step 1: Create Notification Channels"
echo "=================================="
echo ""

# Check if email notification channel exists
EMAIL_CHANNEL_ID=$(gcloud alpha monitoring channels list \
    --filter="displayName:Email" \
    --format="value(name)" \
    --limit=1 2>/dev/null || echo "")

if [ -z "$EMAIL_CHANNEL_ID" ]; then
    echo -e "${YELLOW}Creating email notification channel...${NC}"
    echo "Enter your email address for alerts:"
    read EMAIL_ADDRESS

    gcloud alpha monitoring channels create \
        --display-name="Email" \
        --type=email \
        --channel-labels=email_address=$EMAIL_ADDRESS

    EMAIL_CHANNEL_ID=$(gcloud alpha monitoring channels list \
        --filter="displayName:Email" \
        --format="value(name)" \
        --limit=1)

    echo -e "${GREEN}✓ Email notification channel created: $EMAIL_CHANNEL_ID${NC}"
else
    echo -e "${GREEN}✓ Email notification channel already exists: $EMAIL_CHANNEL_ID${NC}"
fi

echo ""
echo "=================================="
echo "Step 2: Create Cloud Monitoring Dashboard"
echo "=================================="
echo ""

DASHBOARD_FILE="dashboard-crypted-functions.json"

if [ ! -f "$DASHBOARD_FILE" ]; then
    echo -e "${RED}Error: Dashboard file not found: $DASHBOARD_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating dashboard from: $DASHBOARD_FILE${NC}"

# Check if dashboard already exists
EXISTING_DASHBOARD=$(gcloud monitoring dashboards list \
    --filter="displayName:'Crypted Firebase Functions - Production Dashboard'" \
    --format="value(name)" \
    --limit=1 2>/dev/null || echo "")

if [ -n "$EXISTING_DASHBOARD" ]; then
    echo -e "${YELLOW}Dashboard already exists. Updating...${NC}"
    gcloud monitoring dashboards update $EXISTING_DASHBOARD \
        --config-from-file=$DASHBOARD_FILE
    echo -e "${GREEN}✓ Dashboard updated${NC}"
else
    gcloud monitoring dashboards create \
        --config-from-file=$DASHBOARD_FILE
    echo -e "${GREEN}✓ Dashboard created${NC}"
fi

echo ""
echo "=================================="
echo "Step 3: Create Alert Policies"
echo "=================================="
echo ""

# Array of alert policy files
ALERT_FILES=(
    "alert-high-error-rate.yaml"
    "alert-slow-execution.yaml"
    "alert-rate-limit-spikes.yaml"
)

for ALERT_FILE in "${ALERT_FILES[@]}"; do
    if [ ! -f "$ALERT_FILE" ]; then
        echo -e "${RED}Warning: Alert file not found: $ALERT_FILE${NC}"
        continue
    fi

    ALERT_NAME=$(grep "displayName:" "$ALERT_FILE" | head -1 | sed 's/displayName: "\(.*\)"/\1/')

    echo -e "${YELLOW}Creating alert: $ALERT_NAME${NC}"

    # Check if alert already exists
    EXISTING_ALERT=$(gcloud alpha monitoring policies list \
        --filter="displayName:'$ALERT_NAME'" \
        --format="value(name)" \
        --limit=1 2>/dev/null || echo "")

    # Add notification channel to alert file temporarily
    TMP_FILE="${ALERT_FILE}.tmp"
    cp "$ALERT_FILE" "$TMP_FILE"

    # Append notification channel if not already present
    if ! grep -q "notificationChannels:" "$TMP_FILE"; then
        echo "notificationChannels:" >> "$TMP_FILE"
        echo "  - $EMAIL_CHANNEL_ID" >> "$TMP_FILE"
    fi

    if [ -n "$EXISTING_ALERT" ]; then
        echo -e "${YELLOW}Alert already exists. Updating...${NC}"
        gcloud alpha monitoring policies update $EXISTING_ALERT \
            --policy-from-file="$TMP_FILE"
        echo -e "${GREEN}✓ Alert updated: $ALERT_NAME${NC}"
    else
        gcloud alpha monitoring policies create \
            --policy-from-file="$TMP_FILE"
        echo -e "${GREEN}✓ Alert created: $ALERT_NAME${NC}"
    fi

    rm "$TMP_FILE"
done

echo ""
echo "=================================="
echo "Step 4: Set Up Budget Alerts"
echo "=================================="
echo ""

echo -e "${YELLOW}Note: Budget alerts must be configured in Cloud Billing Console${NC}"
echo "URL: https://console.cloud.google.com/billing/$PROJECT_ID/budgets"
echo ""
echo "Recommended Budget Alert:"
echo "  - Budget Amount: \$200/month"
echo "  - Alert Thresholds: 50%, 75%, 90%, 100%"
echo "  - Notification Email: (your email)"
echo ""

echo ""
echo "=================================="
echo "✅ Monitoring Deployment Complete!"
echo "=================================="
echo ""
echo -e "${GREEN}Dashboard URL:${NC}"
echo "https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT_ID"
echo ""
echo -e "${GREEN}Alert Policies:${NC}"
gcloud alpha monitoring policies list --format="table(displayName, enabled)" | grep "Firebase\|Rate Limit"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "1. Visit the dashboard URL to view real-time metrics"
echo "2. Test alerts by triggering errors or slow functions"
echo "3. Set up budget alerts in Cloud Billing Console"
echo "4. (Optional) Add Slack/PagerDuty notification channels"
echo ""
echo "To add additional notification channels:"
echo "  gcloud alpha monitoring channels create --help"
echo ""
