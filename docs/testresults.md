# Test Results Template: Graylog Logging Flow

## Test Session Metadata

- Test Session ID:
- Date:
- Environment:
- Tester(s):
- Graylog Version:
- Change/Release Reference:

## Overall Summary

- Total Test Cases:
- Passed:
- Failed:
- Blocked:
- Pass Rate (%):
- Final Recommendation: Go / No-Go

## Results Table

| ID | Test Case | Priority | Status (Pass/Fail/Blocked) | Evidence | Notes / Defect ID |
| --- | --- | --- | --- | --- | --- |
| TC-01 | Graylog stack health | High |  |  |  |
| TC-02 | Beats input availability | High |  |  |  |
| TC-03 | Syslog forwarding path (514 -> 1514) | High |  |  |  |
| TC-04 | WEF collector receives events | High |  |  |  |
| TC-05 | Winlogbeat forwarding | High |  |  |  |
| TC-06 | Field normalization | High |  |  |  |
| TC-07 | Stream routing | High |  |  |  |
| TC-08 | Dashboard visibility | Medium |  |  |  |
| TC-09 | Alert trigger | High |  |  |  |
| TC-10 | Negative port test | Medium |  |  |  |

## Defect Log

| Defect ID | Title | Severity | Impact | Workaround | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

## Open Risks

1. 
2. 
3. 

## Sign-Off

- Technical Owner:
- Operations Owner:
- Security Owner (if applicable):
- Decision Date:
- Final Decision: Approved / Rework Required

## How To Use This Template

1. Execute tests from [testplan_logging_flow.md](./testplan_logging_flow.md) in order.
2. Fill one row immediately after each test execution.
3. Attach at least one evidence item per test (screenshot, query result, or log excerpt).
4. If a test fails, create a defect entry and reference its ID in the results table.
5. Complete sign-off only when all High-priority test cases are Pass (or have accepted exception).
