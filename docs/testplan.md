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

1. Platform health checks (TC-01, TC-02).
2. Syslog ingestion tests (TC-03).
3. Dashboard tests (TC-08).
4. Alert tests (TC-09).

## 6. Test Cases

| ID | Test Case | Steps | Expected Result | Priority |
| --- | --- | --- | --- | --- |
| TC-01 | Graylog stack health | Check container status and Graylog UI access | All required services are up; UI reachable | High |
| TC-02 | Beats input availability | Verify Beats input status and listening port 5044 | Input is running and accepting traffic | High |
| TC-03 | Syslog forwarding path | Send syslog to host UDP 514; verify arrival in Graylog via input 1514 | Message appears in Graylog search with expected source metadata | High |
| TC-08 | Dashboard visibility | Open dashboard and verify test events are visible in widgets | Widgets show recent events and correct counts/trends | Medium |
| TC-09 | Alert trigger | Send event matching alert condition and monitor notification channel | Alert triggers once with correct context | High |

## 7. How To Execute (Practical Runbook)

### Step A: Health and Inputs

1. Open Graylog UI and confirm all inputs are running.
2. Confirm container health from the central server host.

### Step B: Syslog Path

1. Send a test syslog message to host UDP 514.
2. Confirm message appears in Graylog and was processed by syslog path.
3. Validate metadata (`gl2_remote_ip`, input reference, timestamp).

### Step C: Dashboards and Alerts

1. Verify dashboard widgets display recent test events.
2. Trigger one known alert condition.
3. Confirm alert appears in Graylog and notification channel.
4. Capture evidence (event ID/message, trigger time, receiver).

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
