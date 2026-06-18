# Logging Flow Guide

This document describes the end-to-end logging flow in the Graylog environment, from source systems to dashboards and alerts.

## Purpose

Use this guide to:

1. Understand how logs move through the platform.
2. Validate each stage during onboarding and troubleshooting.
3. Keep architecture decisions consistent across teams.

## High-Level Flow

```text
[Windows/Hyper-V Hosts] -> [WEF Collector + Winlogbeat] -> [Graylog Beats Input:5044]
[Network/Firewalls] -> [Host UDP:514] -> [Docker Forwarding] -> [Graylog Syslog Input:1514]

[Graylog Inputs] -> [Pipelines/Extractors] -> [Streams] -> [OpenSearch Index Sets] -> [Dashboards + Alerts]
```

## Source Flows

### 1. Windows and Hyper-V Event Flow

1. Hyper-V and Windows sources generate event logs.
2. Windows Event Forwarding (WEF) sends selected events to a collector host.
3. Winlogbeat on the collector reads forwarded events.
4. Winlogbeat sends events to Graylog through Beats on TCP `5044`.

Output: Structured Windows/Hyper-V events are available in Graylog for processing.

### 2. Network and Firewall Syslog Flow

1. Switches, routers, and firewalls send Syslog to Graylog host UDP `514`.
2. Docker forwards host UDP `514` to Graylog Syslog UDP input on `1514`.
3. Graylog Syslog input receives messages and enriches metadata (for example source IP and input ID).

Output: Raw infrastructure syslog reaches Graylog ingestion.

## Graylog Processing Flow

After ingestion, all messages follow the same processing path:

1. **Input stage:** Message accepted by Beats or Syslog input.
2. **Parsing stage:** Pipelines/extractors parse vendor formats and map fields.
3. **Normalization stage:** Standard fields are set (for example `device_type`, `event_action`, `event_severity`).
4. **Routing stage:** Stream rules route events to the correct logical stream.
5. **Storage stage:** Messages are indexed into OpenSearch via Index Sets.
6. **Consumption stage:** Dashboards visualize data and alerts evaluate conditions.

## Field Normalization Principles

To keep dashboards reusable across sources:

1. Keep consistent field names for action, severity, source, and destination.
2. Avoid source-specific field names in dashboard queries when normalized alternatives exist.
3. Update parsing rules when vendor log formats change.

## Validation Checklist (End-to-End)

Use this quick checklist after onboarding a new source:

1. Source can reach target port (Windows flow to collector; syslog flow to UDP `514`).
2. Input is running in Graylog (`5044` for Beats, `1514` inside Docker for Syslog).
3. New messages appear in Search.
4. Expected normalized fields are present.
5. Messages enter the correct Stream.
6. Messages are visible in the intended dashboard widgets.
7. Alert conditions trigger correctly (or remain quiet when expected).

## Common Failure Points

1. Device sends Syslog to wrong port (must target host `514`).
2. Docker forwarding from `514` to `1514` is missing or incorrect.
3. WEF subscription scope is incomplete.
4. Winlogbeat service on collector is stopped or misconfigured.
5. Stream rules do not match normalized fields.
6. Dashboard time range hides valid data.



## Related Documentation

- [Technical Analysis](./technical_analysis.md)
- [Configuration Guide](./configuration_guide.md)
- [Syslog Configuration Guide](./syslog_configuration_guide.md)
- [Dashboard Configuration Guide](./dashboard_configuration_guide.md)
- [Troubleshooting Guide](./troubleshooting_guide.md)
