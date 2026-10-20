# Platform Quality Acceptance: Current QAFE_FORM1 Slice

**Status**: Scenarios defined for application 100 page 4 `Course Catalog`; execution is pending an agreed browser/assistive-technology baseline. These checks do not cover Forms 2/3 or the disabled page 6 test harness.

| ID | Platform concern | Action | Expected result | Status |
|---|---|---|---|---|
| F1-PQ-01 | Browser baseline | Record browser name/version, OS, viewport, and zoom; open the authenticated Course Catalog page. | The page loads without console/runtime errors and the three approved columns fit without clipping. | Defined; browser baseline and execution pending. |
| F1-PQ-02 | Keyboard | Use keyboard only to reach the report search, apply/clear a query, navigate the report menu, and return to the application navigation. | Focus order is visible and logical; all controls are operable; no keyboard trap occurs. | Defined; not run. |
| F1-PQ-03 | Screen reader | Inspect page title, report landmark, column headers, result rows, search, and pagination with an approved screen reader. | Page/region names and column/row relationships are announced; sort and search status are perceivable. | Defined; assistive-technology baseline and execution pending. |
| F1-PQ-04 | Responsive layout | Inspect the report at 1280x800 and a 375x812 viewport. | Navigation and three columns remain usable; no incoherent overlap or unintended horizontal clipping. | Defined; not run. |
| F1-PQ-05 | Read-only security | As an authenticated reader, inspect page 4 and attempt direct access to disabled page 6. | Page 4 exposes no write control/process; page 6 is unavailable at runtime. | Partial PASS, 2026-10-20: page 4 has no form/DML; direct page 6 request returned `APEX.PAGE.NOT_FOUND` after test cleanup. |

Record browser/assistive-technology versions and actual results before using this record as a release gate. Do not expose the local preview beyond `127.0.0.1`.