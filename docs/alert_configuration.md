# Alert & Notification Configuration Guide

This guide provides a comprehensive walkthrough for configuring automated alerts and notifications within your Graylog environment. By setting up alerts, you can transform your logging platform from a passive analysis tool into a proactive monitoring system that automatically notifies you of critical events, security threats, and operational issues in real-time.



## 1. Understanding Alerts & Notifications

Graylog's alerting system is composed of two primary components:

*   **Alerts (Event Definitions):** These are the rules that define *what* to look for in your log data. An alert is triggered when specific conditions are met, such as a certain number of failed login attempts, a server reaching high CPU usage, or a critical error message appearing in an application log.
*   **Notifications:** These define *how* you are notified when an alert is triggered. Graylog supports various notification channels, allowing you to receive alerts via email, messaging platforms, or other systems.

This guide will walk you through setting up a notification channel for Microsoft Teams and then creating an alert that uses this channel.



## 2. Configuring Notification Channels

To receive alerts, you first need to configure one or more notification channels. This section explains how to set up a connection to Microsoft Teams.

### Microsoft Teams Integration

Integrating Graylog with Microsoft Teams allows you to send real-time alert notifications directly to a specific Teams channel. This is achieved using an **Incoming Webhook**.

#### Step 2.1: Create an Incoming Webhook in Microsoft Teams


1.  Click the **three dots (...)** in the left sidebar and select **Workflows**.
2.  In the Workflows window, search for **Webhook** and select **Send webhook alerts to a chat/channel**. 
3.  A unique webhook URL will be generated. **Copy this URL** and save it securely. You will need it in the next step.



> **Security Note:** The webhook URL is a sensitive piece of information. Anyone with this URL can post messages to your Teams channel. Treat it like a password and do not share it publicly.

#### Step 2.2: Create the Notification in Graylog

1.  In the Graylog web interface, navigate to **Alerts** > **Notifications**.
2.  Click the **Create Notification** button.
3.  In the notification creation form, provide the following details:
    *   **Title:** A descriptive name for the notification (e.g., "Microsoft Teams - IT Alerts").
    *   **Type:** Select **Teams v2**.
    *   **URL:** Paste the webhook URL you copied from Microsoft Teams.
4. Graylog uses a template to format the message sent to Teams. You can customize the message to your needs/preferences



5.  Click **Save**.

Your Microsoft Teams notification channel is now configured. You can test it by using the "Execute Test Notification" feature in Graylog.



## 3. Configuring Alerts

With a notification channel in place, you can now create alerts that will use this channel to notify you of events.

### Example: High CPU Usage Alert

This example demonstrates how to create an alert that triggers when a server's CPU usage exceeds a certain threshold. This assumes you are collecting performance metrics from your servers.

#### Step 3.1: Create an Event Definition

1.  In the Graylog web interface, navigate to **Alerts** > **Event Definitions**.
2.  Click **Create Event Definition**.
3.  Fill in the following details:
    *   **Title:** A descriptive name for the alert (e.g., "High CPU Usage on Windows Servers").
    *   **Description:** A brief explanation of what the alert is for.
    *   **Priority:** Set the priority of the alert (e.g., "High").
4.  Configure the **Filter & Aggregation**:
    *   **Search Query:** Define a query that isolates the logs you want to monitor. For example, if your CPU metrics are in a specific stream, you might use `stream_id: <your_stream_id> AND metric_name: "cpu_usage"`.
    *   **Create Events for Definition if...:** Select **Filter has results**.
    *   **...in the last:** Set the time window for the search (e.g., `5 minutes`).
5.  Configure the **Fields**:
    *   You can add fields from the log messages to be included in the alert notification. For example, you might want to include the `hostname` and `cpu_usage` fields.
6.  Configure the **Notifications**:
    *   Click the **Add Notification** button.
    *   Select the notification channel you created earlier (e.g., "Microsoft Teams - IT Alerts").
    *   Configure any additional notification settings.
7.  Click **Save**.

Your alert is now active. If the conditions you defined are met, Graylog will trigger the alert and send a notification to your Microsoft Teams channel.



## Next Steps

This guide has provided a basic overview of configuring alerts and notifications. You can now expand on this by:

*   Creating more notification channels for different teams or services (e.g., email, Slack, PagerDuty).
*   Developing more complex alert definitions using Graylog's powerful search and aggregation capabilities.
*   Customizing the notification templates to include more detailed information from the triggering events.

For more advanced configurations, refer to the official Graylog documentation.
