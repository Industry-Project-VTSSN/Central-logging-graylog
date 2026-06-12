# Syslog Ingestion: Infrastructure Flow & Pipeline Guidance

This document describes the recommended architecture, parsing pipeline, and field normalization rules for infrastructure devices forwarding logs to Graylog over Syslog (UDP).
Use this guide when onboarding switches, firewalls, routers, and other network/security appliances so their telemetry is normalized and consumable by unified dashboards.

---
## Prerequisites

- **Network port:** Ensure UDP `1514` is reachable from your devices to the Graylog ingestion host.
- **Device management IPs:** Assign a stable management IP for each device so pipeline identification rules can map sources reliably.
- **Graylog input:** A running **Syslog UDP** `Input` bound to `1514`.
---
## Architecture Overview

```
[ Generic End Devices ] ──(UDP:1514)──> [ Graylog Input ] ──> [ Pipeline Processing ] ──> [ OpenSearch Index ] ──> [ Dashboards ]
```

--- 
- Device layers: Core, Edge/Access, Security Appliances, Directory/Core Services.
- Processing stages: Input metadata extraction → Pipeline parsing & normalization → Stream routing → Indexed storage → Dashboarding.

---
## Data Journey (High Level)

1. Source devices forward syslog messages via UDP to Graylog on `1514`.
2. The Graylog **Syslog UDP Input** captures each packet and enriches it with network metadata (`gl2_remote_ip`, `gl2_source_input`, `timestamp`).
3. Messages enter a processing pipeline where extractors and Grok rules normalize fields and classify device types.
4. Normalized messages are routed into Streams that enforce retention, access controls, and downstream processing.
5. Events are indexed in OpenSearch with unified field mappings so dashboards can aggregate across vendors.

---
## Ingestion Matrix (Examples)

The following table maps common infrastructure device types to recommended parsing rules and target streams.

| Example Device Type | Vendor Example | Device Category | Parsing Rule / Pipeline Stage | Target Stream |
| --- | --- | --- | --- | --- |
| Core Switches | Aruba | Core Switch | ArubaOS-CX Grok Filter | Net-Core-Switches |
| Edge Switch Stacks | Ruckus | Edge Switch | FastIron/ICX Parser | Net-Edge-Switches |
| Firewalls | WatchGuard | Firewall | WG-CEF / XML Extractor | Net-Firewalls |
| Hyper-V Hosts | Microsoft | Hypervisor | EventLog/Syslog Agent | Srv-Infrastructure |
| Domain Controllers | Microsoft | Identity Provider | Winlogbeat / Syslog | Srv-Directory-Services |
| DHCP Servers | Microsoft | Core Services | DHCP Log Extractor | Srv-Core-Services |

---
## Global Field Mapping

Enforce these unified field names in your pipeline extractors to keep dashboards consistent across device types.

| Unified Field Name | Description | Example Value |
| --- | --- | --- |
| infrastructure_vendor | Hardware or software manufacturer | Aruba, WatchGuard, Microsoft |
| device_type | Architectural role of the asset | Core Switch, Firewall, Identity Provider |
| src_ip | Originating IP address for the event | 10.1.2.100 |
| dst_ip | Destination IP address for the event | 10.2.3.4 |
| dst_port | Destination port of the network flow | 443 |
| event_action | Action or result from the event | Allow, Deny, Account-Lockout |
| event_severity | Normalized severity tier | Informational, Warning, Critical |

---
> ⚠️ **Operational Rule:**
>
> When onboarding a new device, assign a static management IP, configure syslog to target UDP `1514`, and add the IP (or subnet) to the appropriate pipeline device-identification rules. This ensures logs are parsed and routed to the correct streams without dashboard changes.

---
## Next Steps

- Verify the Graylog `Syslog UDP` input is active and listening on `1514`.
- Add device management IPs to your asset identification table used by pipelines.
- Create or update Streams and Index Sets referenced in the Ingestion Matrix.

For configuring Inputs, Streams, and Index Sets, see the Central [Configuration Guide](./configuration_guide.md).
# Graylog Architecture: Infrastructure Syslog Ingestion Flow

This document outlines the data flow and normalization process for infrastructure devices forwarding logs to Graylog via **Syslog UDP**.

Because different vendors and device types format syslog data uniquely, this generalized architecture utilizes an ingestion pipeline to parse, tag, and normalize logs before they populate unified dashboards.

---

## Log Flow Architecture

```
[ Generic End Devices ] ──(UDP:1514)──> [ Graylog Input ] ──> [ Pipeline Processing ] ──> [ OpenSearch Index ] ──> [ Dashboards ]
  - Core Infrastructure                  - Syslog UDP          - Device Identification         - Cold/Warm Storage         - Network Overview
  - Edge/Access Layers                                         - Field Normalization                                       - Security & Access
  - Security Appliances                                        - Stream Routing                                            - Server Health
  - Directory & Core Services

```

---

## Step-by-Step Data Journey

### 1. The Source (Infrastructure Devices)

Endpoints are configured to forward system events over the network.

* **Protocol:** UDP (User Datagram Protocol) to minimize performance overhead on production hardware.
* **Target Port:** `1514` (Avoids standard Linux privileged port restrictions under port 1024).

### 2. The Gatekeeper (Graylog Input)

A single **Syslog UDP Input** listens globally on port `1514`. Upon packet arrival, Graylog automatically extracts network layer metadata:

* `gl2_remote_ip` (The sending device's management IP)
* `gl2_source_input` (The unique Input ID)
* `timestamp` (Time received by Graylog)

### 3. The Factory (Pipelines & Extractors)

The raw message string enters a multi-stage processing pipeline to transform unstructured text into key-value pairs:

1. **Device Identification:** The pipeline checks the incoming `gl2_remote_ip` against defined asset groups and subnets.
2. **Parsing (Grok/JSON):** Variable log structures (e.g., standard firewall CEF/XML formats vs. switch-specific CLI formatting) are parsed into standardized fields.
3. **Classification:** Logs are tagged with generalized metadata (`device_category`, `vendor`).

### 4. The Sorting Hat (Streams)

With metadata attached, logs are routed into functional **Streams** based on device roles. Streams handle data retention rules and user access controls (e.g., separating network-level event routing from system-level event routing).

### 5. The Library & Interface (Storage & Visualization)

Logs are indexed into **OpenSearch**. Because fields are normalized globally during Step 3, a single dashboard widget can aggregate data from entirely different hardware types simultaneously.

## Ingestion Matrix & Pipeline Reference Examples

The following matrix illustrates how general infrastructure nodes are mapped into the ingestion pipeline logic:

| Example Device Type | Vendor Example | Device Category | Parsing Rule / Pipeline Stage | Target Stream |
| --- | --- | --- | --- | --- |
| `Core Switches` | Aruba | Core Switch | ArubaOS-CX Grok Filter | `Net-Core-Switches` |
| `Edge Switch Stacks` | Ruckus | Edge Switch | FastIron/ICX Parser | `Net-Edge-Switches` |
| `Firewalls` | WatchGuard | Firewall | WG-CEF / XML Extractor | `Net-Firewalls` |
| `Hyper-V Hosts` | Microsoft | Hypervisor | EventLog/Syslog Agent | `Srv-Infrastructure` |
| `Domain Controllers` | Microsoft | Identity Provider | Winlogbeat / Syslog | `Srv-Directory-Services` |
| `DHCP Servers` | Microsoft | Core Services | DHCP Log Extractor | `Srv-Core-Services` |


## Global Field Mapping Schema

To maintain dashboard consistency across all hardware types, pipeline extractors must enforce these **Unified Field Names**:

| Unified Field Name | Description | Example Target Value |
| --- | --- | --- |
| `infrastructure_vendor` | Hardware or software manufacturer | `Aruba`, `WatchGuard`, `Microsoft` |
| `device_type` | Architectural role of the asset | `Core Switch`, `Firewall`, `Identity Provider` |
| `src_ip` | Originating IP of a network connection or event | Network Client IP |
| `dst_ip` | Destination IP of a network connection or event | Target Service IP |
| `dst_port` | Target port of the network traffic | `443`, `53` |
| `event_action` | Action taken by the system | `Allow`, `Deny`, `Account-Lockout`, `Link-Down` |
| `event_severity` | Standardized severity tier | `Informational`, `Warning`, `Critical` |

> 📌 **Dashboard Operational Rule:**
> When introducing a new device to the environment, assign it a static management IP within the appropriate subnet, point its syslog to port `1514`, and map its IP to the corresponding pipeline rule. The data will automatically populate the main dashboards without requiring structural layout modifications.