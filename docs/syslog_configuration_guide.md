# Syslog Ingestion: Infrastructure Flow & Pipeline Guidance

This document describes the recommended architecture, parsing pipeline, and field normalization rules for infrastructure devices forwarding logs to Graylog over Syslog (UDP).
Use this guide when onboarding switches, firewalls, routers, and other network/security appliances so their telemetry is normalized and consumable by unified dashboards.


## Prerequisites

- **Network port:** Ensure UDP `514` is reachable from your devices to the Graylog ingestion host.
- **Docker forwarding:** Forward incoming syslog traffic inside Docker from UDP `514` to the Graylog Syslog UDP input on `1514`.
- **Device management IPs:** Assign a stable management IP for each device so pipeline identification rules can map sources reliably.
- **Graylog input:** A running **Syslog UDP** `Input` bound to `1514` inside the Docker network.

## Architecture Overview

```
[ Generic End Devices ] ──(UDP:514)──> [ Docker Port Forwarder ] ──(UDP:1514)──> [ Graylog Input ] ──> [ Pipeline Processing ] ──> [ OpenSearch Index ] ──> [ Dashboards ]
```

--- 
- Device layers: Core, Edge/Access, Security Appliances, Directory/Core Services.
- Processing stages: Input metadata extraction → Pipeline parsing & normalization → Stream routing → Indexed storage → Dashboarding.


## Data Journey (High Level)

1. Source devices forward syslog messages via UDP to the Graylog host on `514`.
2. Docker forwards the incoming traffic internally to the Graylog **Syslog UDP Input** on `1514`, which captures each packet and enriches it with network metadata (`gl2_remote_ip`, `gl2_source_input`, `timestamp`).
3. Messages enter a processing pipeline where extractors and Grok rules normalize fields and classify device types.
4. Normalized messages are routed into Streams that enforce retention, access controls, and downstream processing.
5. Events are indexed in OpenSearch with unified field mappings so dashboards can aggregate across vendors.


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
> When onboarding a new device, assign a static management IP, configure syslog to target UDP `514`, and add the IP (or subnet) to the appropriate pipeline device-identification rules. Docker forwards the traffic internally to Graylog on `1514`, ensuring logs are parsed and routed to the correct streams without dashboard changes.


## Next Steps

- Verify the Graylog `Syslog UDP` input is active and listening on `1514` inside Docker.
- Add device management IPs to your asset identification table used by pipelines.
- Create or update Streams and Index Sets referenced in the Ingestion Matrix.

For configuring Inputs, Streams, and Index Sets, see the Central [Configuration Guide](./configuration_guide.md).
