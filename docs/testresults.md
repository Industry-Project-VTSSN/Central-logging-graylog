# Test Results Template: Graylog Logging Flow

## Overall Summary

- Total Test Cases: 5
- Passed: 5
- Failed: 0
- Blocked: 0
- Pass Rate (%): 100%
- Final Recommendation: Go

## Results Table

| ID | Test Case | Priority | Status (Pass/Fail/Blocked) | Evidence | Notes / Defect ID |
| --- | --- | --- | --- | --- | --- |
| TC-01 | Graylog stack health | High | Pass | docker compose ps - all services running; Graylog web UI accessible | All nodes online |
| TC-02 | Beats input availability | High | Pass | System > Inputs shows Beats port 5044 RUNNING; netstat confirms port open | TCP 5044 verified |
| TC-03 | Syslog forwarding path (514 -> 1514) | High | Pass | docker compose port mapping verified; test syslog UDP received; messages in Search | Host 514 -> Container 1514 OK |
| TC-08 | Dashboard visibility | Medium | Pass | Infrastructure Health dashboard displays data; widgets render without errors | Last 1 hour timerange tested |
| TC-09 | Alert trigger | High | Pass | Test alert fired and notification delivered; timestamp recorded | Confirmation received |

## Defect Log

| Defect ID | Title | Severity | Impact | Workaround | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

## Open Risks

1. 
2. 
3. 

## Sign-Off

- Technical Owner: Operations Team
- Operations Owner: ICT Operations
- Security Owner (if applicable): ICT Security
- Decision Date: 2026-06-18
- Final Decision: Approved

## How To Use This Template

1. Execute tests from [testplan_logging_flow.md](./testplan_logging_flow.md) in order.
2. Fill one row immediately after each test execution.
3. Attach at least one evidence item per test (screenshot, query result, or log excerpt).
4. If a test fails, create a defect entry and reference its ID in the results table.
5. Complete sign-off only when all High-priority test cases are Pass (or have accepted exception).
