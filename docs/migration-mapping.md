# Forms to APEX Behavior Mapping

This is a behavior-level mapping based on README, SQL, and Forms2XML. APEX components listed below are candidates, not a fixed implementation. Preserve behavior only after the owner approves its source and acceptance test.

| Forms source / journey | Observed Forms behavior | Candidate APEX behavior | Validation / unresolved decision |
|---|---|---|---|
| `QAFE_FORM1`, COURSE block | Query source `course`; block and items allow query; `WHEN-NEW-FORM-INSTANCE` sets `:global.user_id` to `Qafe`, navigates to COURSE, and executes a query. Block `WhereClause` and `OrderByClause` are empty. The SQL view projects eight COURSE columns. Block DML flags are enabled; PRE-INSERT assigns sequence/audit values and PRE-UPDATE refreshes audit values. | Local demo only: authenticated user of the local workspace may read `COURSE_NO`, `DESCRIPTION`, and `COST`; sort `COURSE_NO` ascending; page size 10; no writes. | Owner approved these demo parameters on 2026-10-19; they are not claims about Forms defaults or production behavior. No explicit source filter, ordering, or maximum fetch count is defined; item-level query mode is available, but effective Forms matching semantics need runtime confirmation. `COURSE_NO` has blank `ColumnName`. The SQL view's UPDATE/DELETE branches use `WHERE 1 = 0`; resolve before any DML implementation. |
| `QAFE_FORM2`, INSTRUCTOR | Initial window is Instructors; DML flags enabled; ZIP double-click invokes list values; pre-insert sequence/audit, pre-update audit; buttons open Course and Student windows. | Instructor report/form with a searchable ZIP lookup and explicit navigation to related journeys. | Test LOV selection/return, cancel, missing ZIP, window navigation, CRUD, and access permissions. |
| `QAFE_FORM2`, COURSE and SECTION | COURSE and SECTION blocks are read-only in XML; one master-detail relation joins course number; master delete checks for sections and blocks deletion with a message. | Course report with a related section report or master-detail page; read-only initially. | Test zero/multiple details, query refresh, delete with children, and exact message. Confirm whether the README's grid is editable. |
| `QAFE_FORM2`, STUDENT | Student block DML flags enabled; button returns to Instructor navigation. | Student report/form reachable from the approved navigation. | Test query, CRUD and return navigation. SQL view trigger UPDATE/DELETE no-op discrepancy remains a gate. |
| `QAFE_FORM2`, ZIP_LOV | LOV `ZIP_LOV` uses `ZIP_RG` query `select zip, city, state from zipcode`; ZIP returns to INSTRUCTOR.ZIP, CITY/STATE mappings have no return item. | APEX LOV or dialog lookup; display and return values must match the approved user flow. | Test select, cancel, no result, stale ZIP and data security. Confirm whether CITY/STATE should populate. |
| `QAFE_FORM3`, COURSE | Query on start; POST-QUERY computes section and student counts; cost validation rejects values `< 5` with a message; button toggles STUDENTCOUNT visibility. | Course form/report with read-only derived counts and a visible/hidden detail affordance if users confirm it is useful. | Test count values and zero records. Boundary 5 is accepted by code although message says greater than 5. Confirm intended threshold. |
| `QAFE_FORM3`, SECTION | SECTION block executes query on entry; COURSE_NO validation queries COURSE, shows missing-course message and fails. | Related SECTION form/grid with a server-side existence validation. | Exported trigger fetch target is `:course.course_no`, not `:section.course_no`; resolve before implementation and test existing/missing course. |
| `QAFE_FORM3`, navigation | Button opens WINDOW2 and moves to SECTION; close program hides window and returns focus to COURSE.COURSE_NO. | Web page/region navigation with explicit return path and preservation/cancellation of unsaved changes. | Test unsaved-change prompt, back navigation, focus order, keyboard and responsive behavior. |
| `STUDENT` validation SQL | BEFORE INSERT/UPDATE rejects null FIRST_NAME with -20101; package helper performs ZIP lookup and sets a message if absent. | Server-side APEX validation/process, retaining database constraints for invariants shared by all clients. | Verify exact message timing and rollback on isolated data; confirm Forms callers and PL/SQL invocation. |

## Cross-cutting mapping rules

- Do not translate a Forms trigger by event name alone. Preserve its inputs, condition, side effects, message, transaction boundary, and failure result.
- Use standard APEX form/report/grid/master-detail patterns only after the XML confirms data source and the owner approves the web journey.
- Enforce authorization and validation server-side. Keep all business writes denied until the role matrix is approved.
- The desktop windows/canvases have no one-to-one visual requirement. Document responsive layout, navigation, accessibility, and keyboard alternatives as acceptance criteria.
## QAFE_FORM1 First Read Slice

The first source-contract test is recorded in `tests/acceptance/US2-search.md` as `F1-SRC-01`. It verifies exported XML facts only; it is not an execution test of Oracle Forms or APEX.

- The `COURSE` block uses query source `course`, has `QueryAllowed=true`, an empty `WhereClause` and `OrderByClause`, and `MaximumRecordsFetched=0` in the export.
- All eight block items are visible and query-enabled in the export. The `COURSE_NO` item's `ColumnName` is empty and remains a binding discrepancy.
- The module startup trigger sets the Forms global to the literal `Qafe`, navigates to COURSE, and invokes `execute_query()`. This literal is not an approved APEX identity source.
- The SQL view exposes PREREQUISITE, COURSE_NO, DESCRIPTION, COST, CREATED_BY, CREATED_DATE, MODIFIED_BY, and MODIFIED_DATE. Its INSERT branch writes COURSE; its UPDATE and DELETE branches match no rows (`WHERE 1 = 0`).
- The export defines no explicit filter, ordering, or user-facing empty-state message. Do not invent these for APEX.
- APEX read acceptance remains blocked by the unknown actor/read scope in `docs/security-matrix.md`; no migrated APEX page exists to execute the behavioral scenario yet.
- For the local demonstration only, the owner approved authenticated workspace users, the three columns `COURSE_NO`, `DESCRIPTION`, and `COST`, ascending `COURSE_NO`, page size 10, and no writes. This does not approve production access or behavior.

- Every row above must be linked to source IDs, requirements, acceptance tests, and proof status in `docs/traceability-matrix.md`.