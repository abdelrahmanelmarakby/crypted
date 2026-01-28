# Phase 4 Deployment Checklist

**Quick reference for deploying Phase 4 enterprise features**

---

## ✅ Pre-Deployment Checklist

- [ ] Phase 3 functions deployed successfully
- [ ] `gcloud` CLI installed and authenticated
- [ ] Owner or Monitoring Admin role in GCP
- [ ] Node.js 22+ installed
- [ ] Current directory: `/functions`

---

## 📦 Step 1: Install Dependencies (5 min)

```bash
cd functions

# Install Cloud Tasks dependency
npm install @google-cloud/tasks@^5.8.0

# Verify
npm list @google-cloud/tasks
```

**Expected:** `@google-cloud/tasks@5.8.0` installed

---

## ⚙️ Step 2: Deploy Cloud Tasks Queues (2 min)

```bash
cd cloud-tasks
chmod +x deploy-queues.sh
./deploy-queues.sh
```

**Expected Output:**
```
✓ Created queue [notification-queue]
✓ Created queue [analytics-queue]
✓ Created queue [cleanup-queue]
```

**Verify:**
```bash
gcloud tasks queues list --location=us-central1
```

---

## 🚀 Step 3: Deploy Updated Functions (5 min)

```bash
cd ..
firebase deploy --only functions
```

**New Functions:**
- [ ] `healthCheck` deployed
- [ ] `processNotificationBatch` deployed
- [ ] `processAnalyticsBatch` deployed

**Test Health Check:**
```bash
curl -X POST https://us-central1-crypted-8468f.cloudfunctions.net/healthCheck
```

**Expected:** All circuit breakers in "CLOSED" state

---

## 📊 Step 4: Deploy Monitoring (10 min)

```bash
cd monitoring
chmod +x deploy-monitoring.sh
./deploy-monitoring.sh
```

**You will be prompted for:**
- [ ] Email address for alerts

**Expected Output:**
```
✓ Email notification channel created
✓ Dashboard created
✓ Alert created: Firebase Function Error Rate > 5%
✓ Alert created: Firebase Function Execution Time > 5s
✓ Alert created: Rate Limit Hits > 100/hour
```

**Verify:**
- [ ] Open dashboard URL (provided in output)
- [ ] Check that metrics are loading

---

## 💰 Step 5: Set Up Budget Alert (5 min)

**Manual step - Go to:**
https://console.cloud.google.com/billing/crypted-8468f/budgets

**Configure:**
- [ ] Budget Name: "Firebase Functions Monthly Budget"
- [ ] Amount: $200/month
- [ ] Thresholds: 50%, 75%, 90%, 100%
- [ ] Email: (your email)

---

## 🧪 Step 6: Validation Tests

### Test 1: Circuit Breaker Health ✅
```bash
curl -X POST https://us-central1-crypted-8468f.cloudfunctions.net/healthCheck
```
- [ ] All breakers show state: "CLOSED"

### Test 2: Dashboard ✅
- [ ] Open dashboard URL
- [ ] Verify all widgets loading
- [ ] Data appears within 2 minutes

### Test 3: Alert Policies ✅
```bash
gcloud alpha monitoring policies list --filter="displayName:Firebase"
```
- [ ] 3 alert policies listed
- [ ] All show enabled: True

### Test 4: Cloud Tasks Queues ✅
```bash
gcloud tasks queues list --location=us-central1
```
- [ ] 3 queues listed
- [ ] All show state: RUNNING

---

## 📈 Step 7: Monitor for 24 Hours

**Check these metrics:**

- [ ] Function invocations: ~145K/month rate
- [ ] Error rate: < 1%
- [ ] P95 latency: < 500ms
- [ ] Circuit breakers: All CLOSED
- [ ] No alert emails received

**If any alerts fire:**
- Review `monitoring/README.md` for response playbooks

---

## ✅ Deployment Complete!

### What You Now Have:

✅ **Automated Alerting**
- 4 critical alert policies
- Email notifications
- Detailed runbooks

✅ **Real-Time Monitoring**
- Cloud Monitoring dashboard
- 10+ metrics tracked
- Visual trend analysis

✅ **Circuit Breakers**
- Firestore breaker
- RTDB breaker
- FCM breaker
- Health check endpoint

✅ **Async Processing**
- 3 Cloud Tasks queues
- Notification batch processor
- Analytics batch processor

✅ **Cost Control**
- $115.40/month total
- 96.2% reduction from original
- Budget alerts configured

---

## 📚 Next Steps

1. **Monitor for 1 week**
   - Check dashboard daily
   - Verify alert policies working
   - Track cost vs. budget

2. **Optional Enhancements** (Low Priority)
   - Redis caching (+$30/month) - if latency critical
   - BigQuery analytics (+$10/month) - if deep analytics needed

3. **Regular Maintenance**
   - Weekly: Review dashboard for trends
   - Monthly: Check cost vs. budget
   - Quarterly: Test all alerts

---

## 🆘 Troubleshooting

**Issue:** Circuit breaker stuck OPEN
- Check `monitoring/README.md` → Circuit Breaker section

**Issue:** Alerts not firing
- Check `monitoring/README.md` → Alert Response Playbooks

**Issue:** Cloud Tasks not processing
- Check function logs: `firebase functions:log --only processNotificationBatch`

**Issue:** Dashboard not loading
- Wait 2 minutes for data to populate
- Refresh browser
- Verify functions are executing

---

## 📞 Support Resources

**Documentation:**
- `PHASE_4_DEPLOYMENT_GUIDE.md` - Full deployment guide
- `monitoring/README.md` - Monitoring & alert runbooks
- `COMPLETE_OPTIMIZATION_SUMMARY.md` - Full project summary

**Consoles:**
- Firebase: https://console.firebase.google.com/project/crypted-8468f
- Cloud Monitoring: https://console.cloud.google.com/monitoring?project=crypted-8468f
- Cloud Tasks: https://console.cloud.google.com/cloudtasks?project=crypted-8468f

---

**Checklist Version:** 1.0
**Last Updated:** January 28, 2026
**Status:** ✅ Ready for Production
