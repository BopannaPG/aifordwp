# Leadership Update: Floor 6 Windows Upgrade — What Happened and What's Next

**Date:** August 14, 2026  
**Prepared for:** Executive Leadership  
**Subject:** Windows 11 Migration Incident — Resolution & Prevention Plan

---

## What Happened

Floor 6 (Legal, 45 users) was upgraded to Windows 11 with modern device management in early August. On Friday afternoon, we deployed a new document management app company-wide to Floor 6 to support their case review work. 

**Monday morning, we discovered a problem:** The app was designed to run automatically when computers started up. That startup process was taking 10-30 minutes to complete—or in some cases, failing entirely—which meant users couldn't log in.

At least a dozen staff reported being blocked from work. For a legal team handling time-sensitive cases, even a few hours of lost access creates real risk: missed compliance deadlines, delayed case reviews, and billable hours lost to downtime.

**The scope was limited:** Floor 6 users were affected; other departments worked normally. The migration itself went well—the app was the problem, not Windows 11.

---

## What We Did — and How We Fixed It

**Within 2 hours of detecting the issue on Monday morning, we:**
1. Removed the app assignment so devices would no longer install it
2. Forced all Floor 6 computers to update their settings
3. Notified users to restart their computers
4. Verified login times returned to normal (under 2 minutes, as expected)

**Users were back to work by mid-morning.** No data was lost or compromised.

---

## What's Being Done to Prevent This Again

We're implementing a three-part system:

### 1. **Better Testing Before Release**
- New apps will be tested on a small group of IT staff for 24 hours before any broader release
- We'll measure how long login takes and confirm the app doesn't interfere with startup
- If anything looks wrong, we stop and ask the vendor for a fix—no company-wide release happens until we're confident

### 2. **Scheduled Deployments with Fallback Plans**
- We won't deploy apps to business-critical teams (like Legal or Finance) on Friday afternoons (when we have limited support over the weekend)
- Every app will have a documented and tested uninstall procedure—we prove we can remove it cleanly before we deploy it
- Three-stage rollouts: IT team → volunteers from target department → full company-wide, with checks between each stage

### 3. **Real-Time Monitoring with Automatic Alerts**
- After an app is released, we're automatically watching how long login takes across affected computers
- If we spot a problem, we get alerted immediately (within minutes, not hours)
- If login times spike, we have the authority to automatically remove the app to restore service
- This gives us a "safety net" if something similar happens in future

---

## What's Still Open

**In Progress:**
- Vendor coordination: We're working with the document management vendor to understand why their app's startup process was blocking logins. We'll require them to fix this before Floor 6 can use the app again, or we'll look for alternative software.
- Three rollout stages are being fully integrated into our change management process (completion target: September 15)
- Real-time monitoring dashboard is being built in Azure (completion target: September 1)

**Outlook:**
- Windows 11 migration for other departments continues as planned. We're applying these same testing and monitoring controls going forward—what we learned from Floor 6 makes all future deployments safer.
- User confidence is high: The issue was detected, fixed, and prevented quickly. Staff saw the problem resolved in hours, not days.

---

## Bottom Line

We've turned an incident into an opportunity to build stronger controls. Floor 6 is operating normally. Future app deployments will have multiple safety gates before reaching end users. And if something does slip through, we'll catch it and fix it within minutes—automatically.

This is what modern IT infrastructure should do: work reliably, fail fast if needed, and give business teams confidence in the technology supporting their work.

---

**Questions? Contact:** DWP Service Delivery Lead | [ext. 4357]
