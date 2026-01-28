# Crypted Firebase Functions - Monitoring & Observability

This directory contains Cloud Monitoring configuration for production observability of Firebase Functions.

## 📊 What's Included

### **1. Cloud Monitoring Dashboard**
- Real-time function invocations
- P95 execution times with thresholds
- Error rates by function
- Active instances tracking
- Firestore operations
- Realtime Database bandwidth
- Monthly invocation trends

**File:** `dashboard-crypted-functions.json`

### **2. Alert Policies**
Four critical alert policies to catch production issues:

1. **High Error Rate** (`alert-high-error-rate.yaml`)
   - Triggers when error rate > 5% for 5 minutes
   - Indicates possible bad deployment or service outage

2. **Slow Execution** (`alert-slow-execution.yaml`)
   - Triggers when P95 execution time > 5 seconds for 5 minutes
   - Indicates performance degradation

3. **Budget Alert** (`alert-budget-exceeded.yaml`)
   - Triggers when monthly cost > $200
   - Expected cost: $155/month

4. **Rate Limit Spikes** (`alert-rate-limit-spikes.yaml`)
   - Triggers when rate limit errors > 100/hour
   - Indicates potential abuse or client bugs

### **3. Deployment Script**
Automated deployment of all monitoring infrastructure.

**File:** `deploy-monitoring.sh`

---

## 🚀 Quick Start

### **Prerequisites**
- `gcloud` CLI installed
- Logged into GCP project `crypted-8468f`
- Owner or Monitoring Admin role

### **Deploy Everything**
```bash
cd functions/monitoring
./deploy-monitoring.sh
```

The script will:
1. ✅ Create email notification channel
2. ✅ Create Cloud Monitoring dashboard
3. ✅ Create all 4 alert policies
4. ✅ Link alerts to notification channel

---

## 📈 Accessing the Dashboard

**Dashboard URL:**
```
https://console.cloud.google.com/monitoring/dashboards?project=crypted-8468f
```

**What to Monitor:**

1. **Function Invocations**
   - Expected: ~145,000/month (98.1% reduction from 7.6M)
   - Alert if sudden spike (> 200K/month)

2. **Execution Time P95**
   - Expected: < 500ms for all functions
   - Alert if > 5 seconds
   - Yellow warning at > 1 second

3. **Error Rate**
   - Expected: < 1%
   - Alert if > 5%

4. **Active Instances**
   - Shows how many function instances are running
   - Should scale up during traffic spikes

5. **Firestore Operations**
   - Reads should be minimal with caching
   - Writes should match user activity

6. **Realtime Database Bandwidth**
   - Active connections from presence system
   - Should match online user count

---

## 🚨 Alert Response Playbook

### **High Error Rate Alert**

**When:** Error rate > 5% for 5 minutes

**Immediate Actions:**
1. Check Firebase Console logs: https://console.firebase.google.com/project/crypted-8468f/functions
2. Identify which function is failing:
   ```bash
   gcloud logging read 'resource.type="cloud_function" AND severity=ERROR' --limit=50
   ```
3. Check recent deployments:
   ```bash
   firebase functions:log --only [function-name]
   ```

**Common Causes:**
- Bad deployment → Roll back
- Firestore connectivity → Check Firebase status
- Rate limiting → Increase limits if legitimate traffic
- External API failure → Implement retry logic

**Escalation:**
- If error rate > 20%, page on-call engineer
- If errors persist > 30 minutes, consider rolling back

---

### **Slow Execution Alert**

**When:** P95 execution time > 5 seconds for 5 minutes

**Immediate Actions:**
1. Check Cloud Monitoring dashboard for slowest functions
2. Review function logs for bottlenecks:
   ```bash
   gcloud logging read 'jsonPayload.duration_ms > 5000' --limit=50
   ```
3. Check if Firestore indexes are missing:
   ```bash
   firebase firestore:indexes
   ```

**Common Causes:**
- Missing Firestore composite indexes
- Cold starts (should be rare with v2)
- Large batch operations (move to Cloud Tasks)
- Memory constraints (increase memory allocation)

**Mitigation:**
1. Add missing indexes: `firebase deploy --only firestore:indexes`
2. Increase memory: Update `memory` in function options
3. Implement caching for frequently accessed data
4. Move heavy operations to async Cloud Tasks

---

### **Budget Alert**

**When:** Monthly cost > $200

**Expected Cost:** $155/month after Phase 4

**Immediate Actions:**
1. Check Firebase Usage & Billing:
   ```
   https://console.firebase.google.com/project/crypted-8468f/usage
   ```
2. Check function invocation counts:
   ```bash
   gcloud logging read 'jsonPayload.function!=""' --format=json | jq '.[] | .jsonPayload.function' | sort | uniq -c
   ```
3. Identify cost spike source

**Common Causes:**
- Sudden traffic spike (viral content, bot attack)
- Rate limiting not working (abuse)
- Function inefficiency (check invocation counts)
- Firestore read/write explosion

**Immediate Mitigation:**
1. Review and tighten rate limits if abuse detected
2. Temporarily disable non-critical functions
3. Enable stricter Firebase Security Rules
4. Contact Firebase support for billing anomalies

**Escalation:**
- If cost > $500/month, escalate to engineering lead immediately

---

### **Rate Limit Spike Alert**

**When:** Rate limit errors > 100/hour

**Immediate Actions:**
1. Identify which users are hitting rate limits:
   ```bash
   gcloud logging read 'jsonPayload.error=~"resource-exhausted"' --format=json | jq '.[] | .jsonPayload.userId' | sort | uniq -c | sort -rn
   ```
2. Review user behavior patterns
3. Check client implementation for retry loops

**Common Causes:**
- Malicious user attempting DoS attack
- Client bug causing infinite retry loop
- Legitimate high-activity user (may need exemption)
- Rate limits too strict for normal usage

**Response Actions:**
1. **Investigate User:** Check userId in logs
2. **Block if Abuse:** Add user to Firestore blocklist
3. **Fix Client Bug:** If legitimate user, check client code for issues
4. **Adjust Limits:** If too strict, update `MAX_REQUESTS_PER_MINUTE` in `functions/index.js`

---

## 🔍 Useful Monitoring Commands

### **View Recent Function Logs**
```bash
# All functions
firebase functions:log --follow

# Specific function
firebase functions:log --only batchStatusUpdate --follow
```

### **View Metrics Logs**
```bash
gcloud logging read 'jsonPayload.function!=""' --limit=50
```

### **View Only Errors**
```bash
gcloud logging read 'resource.type="cloud_function" AND severity=ERROR' --limit=20
```

### **Check Circuit Breaker States**
```bash
# Call healthCheck function
curl -X POST https://us-central1-crypted-8468f.cloudfunctions.net/healthCheck \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)"
```

### **List All Active Functions**
```bash
firebase functions:list
```

### **Check Function Memory Usage**
```bash
gcloud logging read 'resource.type="cloud_function" AND jsonPayload.memoryUsed!=""' --limit=20
```

---

## 🧪 Testing Alerts

### **Test Error Rate Alert**
```javascript
// Deploy a function that intentionally throws errors
exports.testErrorAlert = onCall((request) => {
  throw new HttpsError('internal', 'Test error for alert testing');
});
```

Call the function 10+ times to trigger > 5% error rate.

### **Test Slow Execution Alert**
```javascript
// Deploy a function that sleeps for 6 seconds
exports.testSlowAlert = onCall(async (request) => {
  await new Promise(resolve => setTimeout(resolve, 6000));
  return { success: true };
});
```

### **Test Rate Limit Alert**
Write a script to call any function 150+ times in an hour.

---

## 📊 Circuit Breaker Monitoring

### **Check Circuit Breaker Health**
```bash
# Call healthCheck endpoint
curl -X POST https://us-central1-crypted-8468f.cloudfunctions.net/healthCheck
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-28T10:30:45.123Z",
  "circuitBreakers": {
    "firestore": {
      "name": "firestore",
      "state": "CLOSED",
      "failureCount": 0,
      "successCount": 0,
      "lastStateChange": "2026-01-28T10:00:00.000Z"
    },
    "rtdb": {
      "name": "rtdb",
      "state": "CLOSED",
      "failureCount": 0,
      "successCount": 0,
      "lastStateChange": "2026-01-28T10:00:00.000Z"
    },
    "fcm": {
      "name": "fcm",
      "state": "CLOSED",
      "failureCount": 0,
      "successCount": 0,
      "lastStateChange": "2026-01-28T10:00:00.000Z"
    }
  }
}
```

**States:**
- **CLOSED**: Normal operation ✅
- **HALF_OPEN**: Testing recovery ⚠️
- **OPEN**: Service failing, fail-fast mode 🚨

---

## 🔔 Adding Notification Channels

### **Email (Already Created)**
Email notifications are set up during deployment.

### **Slack**
```bash
# Create Slack notification channel
gcloud alpha monitoring channels create \
  --display-name="Slack - Crypted Alerts" \
  --type=slack \
  --channel-labels=url=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

Update alert policies to include Slack channel.

### **PagerDuty**
```bash
# Create PagerDuty notification channel
gcloud alpha monitoring channels create \
  --display-name="PagerDuty - On-Call" \
  --type=pagerduty \
  --channel-labels=service_key=YOUR_PAGERDUTY_SERVICE_KEY
```

---

## 📅 Regular Maintenance

### **Weekly:**
- Review dashboard for trends
- Check for anomalies in invocation counts
- Verify error rate < 1%

### **Monthly:**
- Review billing vs. budget ($155 expected)
- Check if any functions need optimization
- Update alert thresholds if needed

### **Quarterly:**
- Review all alert policies
- Update runbooks for new functions
- Test all alert notifications

---

## 🎯 Success Metrics

✅ **Zero downtime incidents** detected within 5 minutes
✅ **All critical alerts working** (test monthly)
✅ **P95 latency < 500ms** for all functions
✅ **Error rate < 1%** across all functions
✅ **Monthly cost < $200** ($155 target)
✅ **Circuit breakers prevent cascading failures**

---

## 🆘 Support

**Firebase Console:**
https://console.firebase.google.com/project/crypted-8468f

**Cloud Monitoring Console:**
https://console.cloud.google.com/monitoring?project=crypted-8468f

**Cloud Logging Console:**
https://console.cloud.google.com/logs?project=crypted-8468f

**Firebase Support:**
https://firebase.google.com/support

---

**Last Updated:** January 28, 2026
**Version:** Phase 4 (Enterprise Monitoring)
