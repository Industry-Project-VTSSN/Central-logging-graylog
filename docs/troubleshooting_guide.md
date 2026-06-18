# Graylog Troubleshooting Guide

This guide provides fast diagnostics and recovery steps for common issues in the Graylog environment.
It is optimized for time-critical troubleshooting.

> Scope: Docker-based Graylog stack, Syslog ingestion (host `514` forwarded to container `1514`), and Windows Event forwarding via Winlogbeat.

## Fast Triage Checklist (2 Minutes)

Use this sequence first:

1. Confirm containers are running.
2. Confirm Graylog web/API is reachable.
3. Confirm ingestion port flow (`514` host -> `1514` Graylog input).
4. Confirm messages are arriving in Search.
5. Confirm stream routing and pipeline rules.

## Quick Commands

Run from the central server folder (where `docker-compose.yml` is located).

```bash
# Container health
docker compose ps

# Graylog logs (startup and runtime)
docker compose logs --tail=200 graylog

# OpenSearch logs
docker compose logs --tail=200 opensearch

# MongoDB logs
docker compose logs --tail=200 mongo

# Live Graylog logs (stop with Ctrl+C)
docker compose logs -f graylog
```

## Issue 1: Graylog Web UI Not Reachable

### Symptoms

- `http://<host>:9000` does not load.
- Browser timeout or connection refused.

### Checks

1. Verify container state: `docker compose ps`.
2. Verify published ports in compose.
3. Check Graylog logs for startup failures.

### Common Causes and Fixes

1. **Container not running:** Start stack with `docker compose up -d`.
2. **Port conflict on host 9000:** Change host port mapping or stop conflicting service.
3. **Startup dependency issue (OpenSearch/Mongo):** Fix backend errors first, then restart Graylog.

## Issue 2: No Syslog Data Arriving

### Symptoms

- Devices are configured, but no new messages appear in Search.
- Inputs look active, but message count remains flat.

### Required Port Model

- Devices send to host UDP `514`.
- Docker forwards host UDP `514` to Graylog UDP `1514`.
- Graylog Syslog UDP Input listens on `1514` in the container.

### Checks

1. Confirm device target is correct host IP and UDP `514`.
2. Confirm Docker publishes UDP `514` and forwards correctly.
3. Confirm Graylog Input is running on `1514`.
4. Confirm firewall allows UDP `514` to host.

### Common Causes and Fixes

1. **Wrong device port (`1514` instead of `514`):** Update device config to UDP `514`.
2. **Missing UDP mapping in Docker:** Add UDP `514` mapping and redeploy.
3. **Graylog input bound to wrong port:** Recreate input on `1514`.
4. **Host firewall block:** Allow inbound UDP `514`.

## Issue 3: Messages Arrive but Dashboards Stay Empty

### Symptoms

- Search shows messages, dashboard widgets show no data.

### Checks

1. Verify dashboard time range.
2. Verify widget query and stream filter.
3. Confirm field names used in widgets still match normalized fields.

### Common Causes and Fixes

1. **Time range mismatch:** Switch to `Last 24 hours` temporarily.
2. **Query typo or outdated field:** Update query to current field mapping.
3. **Widget linked to wrong stream/search:** Rebind widget source.

## Issue 4: Stream Routing Not Working

### Symptoms

- Messages only appear in Default Stream.
- Expected stream remains empty.

### Checks

1. Validate stream rules.
2. Check whether `Remove matches from Default Stream` is enabled where intended.
3. Verify pipeline attachment to stream.

### Common Causes and Fixes

1. **Rule never matches:** Adjust field name/operator/value.
2. **Pipeline not connected:** Attach the pipeline to the target stream.
3. **Condition order issue:** Reorder rules or simplify logic for validation.

## Issue 5: Pipeline Parsing Fails

### Symptoms

- Raw messages appear, but normalized fields (`device_type`, `event_action`, etc.) are missing.

### Checks

1. Review Graylog processing/pipeline errors.
2. Test Grok/regex patterns with real sample messages.
3. Confirm vendor message format did not change.

### Common Causes and Fixes

1. **Pattern mismatch:** Update parser to latest log format.
2. **Wrong source classification:** Fix source IP/subnet identification logic.
3. **Rule not executed:** Verify pipeline stage and stream connection.

## Issue 6: Winlogbeat/Windows Events Not Arriving

### Symptoms

- No recent Windows or Hyper-V events in Graylog.

### Checks

1. Confirm forwarding collector is receiving events.
2. Confirm Winlogbeat service is running on the collector.
3. Confirm Beats input in Graylog is active on the configured port.

### Common Causes and Fixes

1. **Subscription issue in WEF:** Revalidate subscription scope and source hosts.
2. **Winlogbeat stopped:** Restart service and review local logs.
3. **Beats input down or wrong port:** Correct Graylog input configuration.

## Issue 7: Slow Search or High Resource Usage

### Symptoms

- Searches are slow.
- Dashboard refresh takes too long.
- Containers show high CPU or memory.

### Checks

1. Check OpenSearch and Graylog logs for backpressure or memory warnings.
2. Check retention policy and index rotation settings.
3. Check dashboard widget count and expensive aggregations.

### Common Causes and Fixes

1. **Too much hot data retained:** Reduce hot retention window.
2. **Heavy widgets:** Simplify aggregations and reduce refresh frequency.
3. **Resource limits too low:** Increase container memory/CPU allocations.

## Issue 8: Permission or Access Problems

### Symptoms

- Users cannot see dashboards or streams.
- Users can edit content they should only view.

### Checks

1. Verify role assignments.
2. Verify dashboard sharing permissions.
3. Validate with a non-admin test account.

### Common Causes and Fixes

1. **Role missing required rights:** Update role scopes.
2. **Dashboard not shared with correct team:** Adjust sharing settings.
3. **Over-privileged role:** Restrict edit/admin permissions.

## Controlled Restart Procedure

Use this when making config changes to inputs, mappings, or connectivity.

```bash
# Restart only Graylog (fastest)
docker compose restart graylog

# Restart full stack

docker compose down
docker compose up -d
```

After restart:

1. Check `docker compose ps`.
2. Check Graylog logs for successful startup.
3. Validate ingestion with a known test event.

## Escalation Package (What to Collect)

Before escalating, collect this bundle:

1. Timestamp of incident and timezone.
2. Affected source(s) and expected stream.
3. Sample raw message (if available).
4. `docker compose ps` output.
5. Last 200 lines of Graylog/OpenSearch logs.
6. Screenshot of input state and stream rules.

## Related Guides

- [Installation Guide](./installation_guide.md)
- [Configuration Guide](./configuration_guide.md)
- [Syslog Configuration Guide](./syslog_configuration_guide.md)
- [Dashboard Configuration Guide](./dashboard_configuration_guide.md)
- [Windows Sidecar Maintenance](./windows_sidecar_maintenance.md)
