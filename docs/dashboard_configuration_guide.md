# Graylog Dashboard Configuration Guide

This guide explains how to create, configure, and validate dashboards in Graylog so operational teams can monitor infrastructure and security events consistently.

> ⚠️ **Prerequisite:** Ensure your Inputs, Streams, and Index Sets are already configured and receiving data. If needed, complete the [Configuration Guide](./configuration_guide.md) first.

## Dashboard Planning (Before You Click)

Define these items first to avoid rework:

1. **Audience:** Who will use this dashboard (NOC, security, system admins)?
2. **Goal:** What decisions should users make from this dashboard?
3. **Data Scope:** Which streams and sources are in scope?
4. **Time Horizon:** Real-time operations, daily review, or incident forensics?
5. **Thresholds:** Which values should trigger immediate action?

## Step 1: Create a New Dashboard

1. Sign in to Graylog.
2. Go to **Dashboards** from the top navigation.
3. Click **Create dashboard**.
4. Enter:
- **Title:** Use a clear name (for example: `Infrastructure Operations - Core`).
- **Description:** Include purpose, owner, and scope.
5. Save the dashboard.

## Step 2: Build Saved Searches for Reuse

Saved Searches keep queries consistent across widgets.

1. Go to **Search**.
2. Select the relevant Stream(s).
3. Build and test your query (for example by source, severity, event type, or vendor).
4. Set a suitable default time range (for example: last 15 minutes, last 24 hours).
5. Click **Save search** and use a descriptive name.

## Step 3: Add Widgets to the Dashboard

Open the dashboard and add widgets based on your saved searches.

Recommended widget set:

1. **Total Messages (Counter):** Quick volume overview.
2. **Messages Over Time (Line/Area):** Trend and burst visibility.
3. **Top Sources (Bar/Table):** Most active hosts or devices.
4. **Top Error/Action Values (Pie/Bar):** Distribution of outcomes (`Allow`, `Deny`, failures).
5. **Recent Critical Events (Data Table):** Latest actionable events.

For each widget:

1. Select the search and visualization type.
2. Configure fields and aggregations.
3. Assign an intuitive widget title.
4. Save and place it on the dashboard grid.

## Step 4: Configure Dashboard Layout and Readability

Use layout rules so responders can read the dashboard quickly during incidents.

1. Put high-priority summary widgets at the top row.
2. Keep trend charts in the center for context.
3. Place detailed tables lower on the page.
4. Use concise, standardized widget names.
5. Avoid too many widgets; prioritize signal over noise.

## Step 5: Set Dashboard Time and Auto-Refresh

1. Set a default global time range suitable for the use case.
- Operations dashboard: often `Last 15 minutes` or `Last 1 hour`.
- Reporting dashboard: often `Last 24 hours` or `Last 7 days`.
2. Enable auto-refresh where needed.
- Real-time monitoring: short interval (for example every 10 to 30 seconds).
- Executive/reporting view: longer interval (for example 1 to 5 minutes).

## Step 6: Configure Access and Sharing

Use Graylog roles to enforce least privilege.

1. Open dashboard sharing/permissions settings.
2. Grant view-only access to operational consumers.
3. Grant edit access only to dashboard maintainers.
4. Validate access with a non-admin account.

## Step 7: Validate Before Production Use

Run this checklist before marking the dashboard complete:

1. Widgets load without errors.
2. Queries return data for expected streams.
3. Time range and refresh behavior are correct.
4. Counts and trends match raw search results.
5. Required users can view the dashboard.
6. Unauthorized users cannot edit it.

## Suggested Baseline Dashboards

Create these dashboards first for broad coverage:

1. **Infrastructure Health:** device availability, error volumes, top noisy sources.
2. **Security Monitoring:** failed logons, denied traffic, critical security events.
3. **Windows/Hyper-V Events:** authentication failures, host events, service failures.
4. **Firewall Activity:** allow/deny trends, top blocked destinations, severity breakdown.

## Operational Maintenance

Review dashboards regularly to keep them reliable.

1. Weekly: verify query accuracy and widget health.
2. Monthly: remove unused widgets and refine noisy ones.
3. After onboarding new sources: update searches, mappings, and visualizations.
4. After incidents: add or improve widgets based on lessons learned.

## Next Steps

After dashboard setup:

1. Configure notification logic in the [Alert Configuration Guide](./alert_configuration.md).
2. Align field names with your ingestion normalization rules in the [Syslog Configuration Guide](./syslog_configuration_guide.md).
3. Document dashboard owners and review cadence in your internal runbook.
