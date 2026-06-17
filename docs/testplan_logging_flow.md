# Test Plan: Graylog Logging Flow

## 1. Test Objective

Validate that the complete logging flow works end-to-end:

1. Windows/Hyper-V events via WEF collector and Winlogbeat to Graylog Beats input (TCP 5044).
2. Network/firewall syslog via host UDP 514 and Docker forwarding to Graylog Syslog input (UDP 1514).
3. Parsing, normalization, stream routing, indexing, dashboards, and alerts.

## 2. Scope

In scope:

1. Ingestion path validation.
2. Pipeline/field normalization validation.
3. Stream and dashboard visibility.
4. Alert trigger validation.

Out of scope:

1. Deep performance benchmarking.
2. Disaster recovery and backup restore tests.

## 3. Preconditions

Before starting tests:

1. Graylog stack is running and web UI is reachable.
2. Graylog inputs are active:
- Beats input on TCP 5044.
- Syslog UDP input on 1514 inside Docker.
3. Host receives syslog on UDP 514 and forwards to container 1514.
4. WEF subscription exists and collector receives Windows/Hyper-V events.
5. Winlogbeat service is running on the collector.
6. Streams, dashboards, and at least one alert rule are configured.

## 4. Test Data

Use controlled test events so you can verify expected outcomes quickly.

1. **Windows test event:** Trigger a known event on a source host (for example failed login attempt in a test account).
2. **Syslog test event:** Send a synthetic syslog message from a test source to host UDP 514.
3. **Alert test event:** Generate an event that matches one configured alert condition.

## 5. Execution Order (Recommended)

Run tests in this order:

1. Platform health checks.
2. Windows/Hyper-V ingestion tests.
3. Syslog ingestion tests.
4. Parsing/normalization tests.
5. Stream routing tests.
6. Dashboard tests.
7. Alert tests.

## 6. Test Cases

| ID | Test Case | Steps | Expected Result | Priority |
| --- | --- | --- | --- | --- |
| TC-01 | Graylog stack health | Check container status and Graylog UI access | All required services are up; UI reachable | High |
| TC-02 | Beats input availability | Verify Beats input status and listening port 5044 | Input is running and accepting traffic | High |
| TC-03 | Syslog forwarding path | Send syslog to host UDP 514; verify arrival in Graylog via input 1514 | Message appears in Graylog search with expected source metadata | High |
| TC-04 | WEF collector receives events | Generate Windows/Hyper-V test event and verify it reaches collector | Event appears on collector in expected channel | High |
| TC-05 | Winlogbeat forwarding | Verify collector event arrives in Graylog | Event visible in search with Windows fields | High |
| TC-06 | Field normalization | Inspect test messages for normalized fields (`device_type`, `event_action`, `event_severity`) | Required normalized fields are present and correct | High |
| TC-07 | Stream routing | Validate that messages are routed to intended stream(s) | Messages appear in target stream and not only default stream (if configured) | High |
| TC-08 | Dashboard visibility | Open dashboard and verify test events are visible in widgets | Widgets show recent events and correct counts/trends | Medium |
| TC-09 | Alert trigger | Send event matching alert condition and monitor notification channel | Alert triggers once with correct context | High |
| TC-10 | Negative port test | Send syslog to wrong port (for test only) and verify no ingestion | No ingestion occurs from wrong port; expected failure behavior confirmed | Medium |

## 7. How To Execute (Practical Runbook)

### Step A: Health and Inputs

1. Open Graylog UI and confirm all inputs are running.
2. Confirm container health from the central server host.

### Step B: Windows/Hyper-V Path

1. Generate a controlled Windows event on a source host.
2. Confirm event arrives at the WEF collector.
3. Confirm Winlogbeat forwards it to Graylog.
4. Search event in Graylog and capture evidence (timestamp, source, stream).

### Step C: Syslog Path

1. Send a test syslog message to host UDP 514.
2. Confirm message appears in Graylog and was processed by syslog path.
3. Validate metadata (`gl2_remote_ip`, input reference, timestamp).

### Step D: Processing and Visibility

1. Validate normalized fields on both Windows and syslog test messages.
2. Confirm stream assignment and index set behavior.
3. Verify dashboard widgets display the test events.

### Step E: Alerts

1. Trigger one known alert condition.
2. Confirm alert appears in Graylog and notification channel.
3. Capture evidence (event ID/message, trigger time, receiver).

## 8. Acceptance Criteria

The flow is accepted when:

1. All High-priority tests pass.
2. No critical data-loss path is observed.
3. Alerts trigger correctly for defined conditions.
4. Dashboards reflect ingested and normalized data.

## 9. Evidence Requirements

For each test case, keep:

1. Test timestamp and tester name.
2. Screenshot or exported search result.
3. Related query/filter used.
4. Pass/fail status and short remark.

## 10. Exit Criteria

You can close testing when:

1. All High-priority tests are Pass.
2. Any Medium failures have a documented workaround or ticket.
3. Final test results are recorded in the test results template.

## Related Documentation

- [Logging Flow Guide](./logging_flow_guide.md)
- [Syslog Configuration Guide](./syslog_configuration_guide.md)
- [Dashboard Configuration Guide](./dashboard_configuration_guide.md)
- [Troubleshooting Guide](./troubleshooting_guide.md)
