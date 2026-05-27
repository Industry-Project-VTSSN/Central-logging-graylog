# Windows Sidecar Operations & Maintenance Guide

This guide provides lifecycle instructions for managing, updating, and troubleshooting existing Graylog Windows Sidecar deployments. Use these procedures when you need to alter what logs are collected or modify a specific server's tags and environment variables.



## 📌 Document Overview
* **Target OS:** Windows Server 2019 / 2022 / 2025
* **Core Components:** Graylog Sidecar Agent & Winlogbeat Collector
* **Prerequisites:** Administrative access to the target Windows host and/or `Admin` permissions within the Graylog Web UI.



## 1. Modifying & Appending Tags on an Existing Host

Use this procedure when a server’s role changes or expands (e.g., a standard Windows server is configured as a Web Server, requiring it to collect both base OS logs and IIS web logs). 

Graylog supports **multi-tagging**, meaning a single host can pull multiple independent configuration profiles simultaneously.

### Step 1: Update the Local Environment File
1. Open **PowerShell as an Administrator**.
2. Open the host's `sidecar.yml` file in Notepad:
```powershell
notepad "C:\Program Files\Graylog\Sidecar\sidecar.yml"
```

3. Locate the 'tags' block sequence and update it with the new tag(s). 
```yaml
tags:
  - windows-core
  - webserver
```

4. Save and close the file.

### Step 2: Restart the Sidecar Service

For the Sidecar to check in with its new identity, you must restart the Windows service:

```powershell
Restart-Service graylog-sidecar
```

## 2. Global Configuration Changes (Adding/Removing Log Channels)

If you need to add a new event log channel (like **IIS** or **DHCP** auditing) across all servers, you do **not** need to touch the Windows servers individually. This is handled entirely through the Graylog Web UI.

1. Log into the Graylog Web UI and navigate to **System** ➔ **Sidecars** ➔ **Configuration**.
2. Click **Edit** next to your Windows configuration profile (e.g., `Windows Servers`).
3. Scroll to the `winlogbeat.event_logs:` section and append your new channel using its exact Windows Event Viewer name:
```yaml
    - name: Microsoft-Windows-TaskScheduler/Operational
      ignore_older: 96h
```


4. Click **Save**.

> 💡 **Behind the Scenes:** Graylog will automatically detect the configuration change, push the updated YAML file to all active Windows Sidecars matching that tag, and gracefully restart the local Winlogbeat instance automatically.


## 3. Updating the Graylog API Token

API tokens expire or may need to be rotated for security compliance. When rotating tokens, you must update the target Windows endpoints so they don't lose connection.

1. Generate your new token in the Graylog Web UI (**System** ➔ **Sidecars** ➔ **Create or reuse a token**).
2. On the Windows host, open PowerShell as an Administrator and edit the environment file:
```powershell
notepad "C:\Program Files\Graylog\sidecar\sidecar.yml"
```


3. Update the `server_api_token` value:
```yaml
server_api_token: "your_new_server_api_token"
```


4. Save the file and restart the service to apply the new credentials:
```powershell
Restart-Service graylog-sidecar
```




## 4. Troubleshooting & Basic Diagnostics

If a host is showing as `Dead` or `Unresponsive` in the Graylog Web UI, use these quick commands to diagnose the issue on the local Windows server.

### Check Service Status

Ensure both the Sidecar controller and the Winlogbeat collector are actually running:

```powershell
Get-Service graylog-sidecar
```

### Review Local Logs

If the service won't start or logs aren't appearing in Graylog, check the local log outputs for error codes (such as firewall blocks or syntax errors in your YAML):

* **Sidecar Agent Logs:** `C:\Program Files\Graylog\Sidecar\logs\sidecar.log`
* **Winlogbeat Collector Logs:** `C:\Program Files\Graylog\Sidecar\logs\winlogbeat.log`

### Test Network Connectivity

Verify that the Windows host can actually talk to the Graylog server over the designated ingestion port (default: `5044`):

```powershell
Test-NetConnection -ComputerName 172.16.0.115 -Port 5044
```


