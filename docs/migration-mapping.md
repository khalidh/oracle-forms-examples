# Forms to APEX Behavior Mapping

This is a behavior-level mapping based on README, SQL, and Forms2XML. APEX components listed below are candidates, not a fixed implementation. Preserve behavior only after the owner approves its source and acceptance test.

| Forms source / journey | Observed Forms behavior | Candidate APEX behavior | Validation / unresolved decision |
|---|---|---|---|
| `QAFE_FORM1`, COURSE block | Query source `course`; block and items allow query; `WHEN-NEW-FORM-INSTANCE` sets `:global.user_id` to `Qafe`, navigates to COURSE, and executes a query. Block `WhereClause` and `OrderByClause` are empty. The SQL view projects eight COURSE columns. Block DML flags are enabled; PRE-INSERT assigns sequence/audit values and PRE-UPDATE refreshes audit values. | Local preview: authenticated user may read only `COURSE_NO`, `DESCRIPTION`, and `COST`; sort `COURSE_NO` ascending; page size 10; no writes. Future approved CRUD target must persist all operations. | Owner approved the read-only preview on 2026-10-19. On 2026-10-20 the owner confirmed that the `WHERE 1 = 0` UPDATE/DELETE branches in `V_QAFE_FORM1_COURSE_TRG` are defects, not target behavior; record this as T020 below. This does not authorize writes in the preview or production. `COURSE_NO` has blank `ColumnName`; Forms runtime binding remains unverified. |
| `QAFE_FORM2`, INSTRUCTOR | Initial window is Instructors; DML flags enabled; ZIP double-click invokes list values; pre-insert sequence/audit, pre-update audit; buttons open Course and Student windows. | Page 7 Builder-only report and page 8 guarded base-table form, with a ZIP select list. | Components and server-side guards are deployed; CRUD, LOV selection, and runtime navigation remain untested. |
| `QAFE_FORM2`, COURSE and SECTION | COURSE and SECTION blocks are read-only in XML; one master-detail relation joins course number; master delete checks for sections and blocks deletion with a message. | Page 11 read-only Course Overview links each Description to page 13, passing COURSE_NO to a hidden item; page 13 filters SECTION by that value. | Builder-only filter/handoff implemented. Runtime COURSE 454 reached the expected empty state; matching-section behavior remains untested because SECTION is read-only and empty. No delete action is exposed. |
| `QAFE_FORM2`, STUDENT | Student block DML flags enabled; button returns to Instructor navigation. | Page 9 Builder-only report and page 10 guarded base-table form. | Components and server-side guards are deployed; CRUD, FIRST_NAME error propagation, and return navigation remain untested. |
| `QAFE_FORM2`, ZIP_LOV | LOV `ZIP_LOV` uses `ZIP_RG` query `select zip, city, state from zipcode`; ZIP returns to INSTRUCTOR.ZIP, CITY/STATE mappings have no return item. | Page 8/10 select lists display ZIP, CITY, STATE and return ZIP only. | SQL LOVs are configured; synthetic ZIP `99999` exists. Runtime selection/persistence remains untested; CITY/STATE return is not assumed. |
| `QAFE_FORM3`, COURSE | Query on start; POST-QUERY computes section and student counts; cost validation rejects values `< 5` with a message; button toggles STUDENTCOUNT visibility. | Course form/report with read-only derived counts and a visible/hidden detail affordance if users confirm it is useful. | Test count values and zero records. Boundary 5 is accepted by code although message says greater than 5. Confirm intended threshold. |
| `QAFE_FORM3`, SECTION | SECTION block executes query on entry; COURSE_NO validation queries COURSE, shows missing-course message and fails. | Related SECTION form/grid with a server-side existence validation. | Exported trigger fetch target is `:course.course_no`, not `:section.course_no`; resolve before implementation and test existing/missing course. |
| `QAFE_FORM3`, navigation | Button opens WINDOW2 and moves to SECTION; close program hides window and returns focus to COURSE.COURSE_NO. | Web page/region navigation with explicit return path and preservation/cancellation of unsaved changes. | Test unsaved-change prompt, back navigation, focus order, keyboard and responsive behavior. |
| `STUDENT` validation SQL | BEFORE INSERT/UPDATE rejects null FIRST_NAME with -20101; package helper performs ZIP lookup and sets a message if absent. | Server-side APEX validation/process, retaining database constraints for invariants shared by all clients. | Verify exact message timing and rollback on isolated data; confirm Forms callers and PL/SQL invocation. |

## Cross-cutting mapping rules

- Do not translate a Forms trigger by event name alone. Preserve its inputs, condition, side effects, message, transaction boundary, and failure result.
- Use standard APEX form/report/grid/master-detail patterns only after the XML confirms data source and the owner approves the web journey.
- Enforce authorization and validation server-side. Keep operations denied by default except for the explicitly approved local Form 1 read slice and local Form 2 Builder CRUD boundary.
- The desktop windows/canvases have no one-to-one visual requirement. Document responsive layout, navigation, accessibility, and keyboard alternatives as acceptance criteria.

## QAFE_FORM2 Related Data Mapping (T026)

| Forms journey | Confirmed source behavior | APEX candidate | Desktop-to-web difference / remaining gate |
|---|---|---|---|
| COURSE to SECTION | Relation `COURSE_SECTION` joins `SECTION.COURSE_NO = COURSE.COURSE_NO`; `ON-POPULATE-DETAILS` queries details. COURSE and SECTION blocks are read-only in XML. | Pages 11/13 are read-only reports; Course Overview passes COURSE_NO to Section Overview, which filters by the key. | Filter and handoff are implemented and the empty-detail runtime case passed. Do not claim full master-detail equivalence until a matching SECTION fixture is separately authorized and tested. |
| Course master delete | `ON-CHECK-DELETE-MASTER` checks for SECTION children and blocks deletion with an exact message. | Pages 11/13 expose no delete action; COURSE remains read-only. | The source parent-delete scenario is not executable in the approved target scope; preserve read-only behavior. |
| INSTRUCTOR ZIP lookup | `ZIP_LOV` uses `ZIP_RG` query `select zip, city, state from zipcode`; only ZIP returns to `INSTRUCTOR.ZIP`; double-click calls `LIST_VALUES`. | Pages 8/10 use SQL select lists displaying ZIP, CITY, STATE and returning ZIP. | The owner approved local Builder access to these fields. CITY/STATE return behavior is not present in XML; test the ZIP binding at runtime. |
| INSTRUCTOR/STUDENT maintenance | XML enables DML flags on INSTRUCTOR and STUDENT; SQL view triggers insert to base tables but UPDATE/DELETE use `WHERE 1 = 0`. | Pages 8/10 use guarded base-table DML with generated keys, audit attribution, ownership predicates, and process authorization. | Owner approved this local target correction. Runtime persistence and database-error rollback remain unverified; legacy triggers remain unchanged. |
| Window navigation | Buttons query/show COURSE and STUDENT windows; return buttons hide windows and move focus to INSTRUCTOR.FIRST_NAME. | Explicit web page/region navigation with a stable return path and focus handling. | Browser back, responsive layout, unsaved-change prompt, and focus order differ from desktop windows and require acceptance tests. |

Detailed scenarios are in `tests/acceptance/US5-related-data.md`. The owner-approved local Form 2 scope is limited to `QAFE_FORMS_BUILDER` in `QAFE_CLEAN`; this mapping does not authorize legacy-PDB or production exposure.

## QAFE_FORM2 CRUD Decision (2026-10-20)

- The owner authorized local Form 2 CRUD in `QAFE_CLEAN` for the editable INSTRUCTOR and STUDENT journeys, using `QAFE_FORMS_BUILDER`; COURSE and SECTION stay read-only according to the exported block flags.
- The `V_QAFE_FORM2_INSTRUCTOR_TRG` and `V_QAFE_FORM2_STUDENT_TRG` UPDATE/DELETE branches use `WHERE 1 = 0`. Treat them as defects for the APEX target; do not modify the legacy triggers or report those no-ops as successful writes. Implement guarded DML against base tables.
- Use synthetic fixtures only. Do not migrate historical or production personal data. Remove test fixtures after acceptance; no network/production access is authorized.

## QAFE_FORM1 CRUD Decision (T020)

- **Owner decision, 2026-10-20**: treat the `UPDATE` and `DELETE` branches in `V_QAFE_FORM1_COURSE_TRG` as defects to correct for the APEX CRUD target; do not reproduce their `WHERE 1 = 0` no-op behavior.
- **Sources**: `script/student-db-script.sql`, trigger `STUDENT.V_QAFE_FORM1_COURSE_TRG`; Forms2XML triggers `F1-TR-02` (`COURSE.PRE-INSERT`) and `F1-TR-03` (`COURSE.PRE-UPDATE`) in `docs/trigger-analysis.md`.
- **Boundary**: this decision resolves the behavior discrepancy only. APEX write access and write-test execution remain disabled until a write actor is approved and a disposable COURSE fixture with a reset procedure is approved. Never use preview rows 454/455/456 for write tests.

## QAFE_FORM1 CRUD Implementation (T021)

- Application 100 export includes page 6 `Course CRUD Test Harness`, protected by `QAFE CRUD TEST BUILDER ONLY`. Its form source is restricted to `DESCRIPTION = 'QAFE CRUD TEST - QAFE_FORMS_BUILDER'` and `CREATED_BY = 'QAFE_FORMS_BUILDER'`.
- The page's custom PL/SQL process inserts via `COURSE_NO_SEQ`, sets audit fields from `APP_USER`, and limits update/delete predicates to the exact marker row owned by the Builder. It checks that only one fixture exists and verifies one affected row for update/delete.
- The owner authorized one temporary test fixture on 2026-10-20. Create (COURSE 457, cost 15), update (cost 25 with creation audit preserved and modification audit refreshed), and delete all passed with database read-back. The marker count is zero after cleanup; rows 454/455/456 are unchanged. Sequence value 457 remains consumed.
- After testing, page 6 was set to Build Option `Commented Out`, Page Access Protection `No URL Access`, and `P6_COURSE_NO` checksum protection was restored. A direct runtime request returned `APEX.PAGE.NOT_FOUND`. No ongoing write permission is enabled.
- The duplicate-key negative scenario passed with `CRSE_PK`; broader transaction-failure tests remain unrun. Page 6 is disabled after the test and page 4 `Course Catalog` remains read-only.
## QAFE_FORM1 First Read Slice

The first source-contract test is recorded in `tests/acceptance/US2-search.md` as `F1-SRC-01`. It verifies exported XML facts only; it is not an execution test of Oracle Forms or APEX.

- The `COURSE` block uses query source `course`, has `QueryAllowed=true`, an empty `WhereClause` and `OrderByClause`, and `MaximumRecordsFetched=0` in the export.
- All eight block items are visible and query-enabled in the export. The `COURSE_NO` item's `ColumnName` is empty and remains a binding discrepancy.
- The module startup trigger sets the Forms global to the literal `Qafe`, navigates to COURSE, and invokes `execute_query()`. This literal is not an approved APEX identity source.
- The SQL view exposes PREREQUISITE, COURSE_NO, DESCRIPTION, COST, CREATED_BY, CREATED_DATE, MODIFIED_BY, and MODIFIED_DATE. Its INSERT branch writes COURSE; its UPDATE and DELETE branches match no rows (`WHERE 1 = 0`).
- The export defines no explicit filter, ordering, or user-facing empty-state message. Do not invent these for APEX.
- The approved local QAFE_FORM1 scope is implemented as application 100, page 4 (`Course Catalog`) in `QAFE_FORMS_CLEAN`; `F1-DEMO-01` passed on the three approved rows. Broader US2 journeys and production read authorization remain gated and untested.
- For the local demonstration only, the owner approved authenticated workspace users, the three columns `COURSE_NO`, `DESCRIPTION`, and `COST`, ascending `COURSE_NO`, page size 10, and no writes. This does not approve production access or behavior.

- Every row above must be linked to source IDs, requirements, acceptance tests, and proof status in `docs/traceability-matrix.md`.