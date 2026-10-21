# Forms Trigger and Rule Analysis

**Evidence**: Three Forms2XML `DUMP=ALL` exports in `docs/forms-exports/` plus `script/student-db-script.sql`. “Observed” refers to exported source text, not an independently tested runtime outcome. Form-to-database trigger bindings marked inferred require owner/runtime confirmation.

## Rules from Forms XML

| ID | Source | Event / condition | Inputs | Observed effect / message | Status / target test |
|---|---|---|---|---|---|
| F1-TR-01 | `QAFE_FORM1_fmb.xml`, FormModule `QAFE_FORM1` | `WHEN-NEW-FORM-INSTANCE` | None shown | Sets `:global.user_id := 'Qafe'`, goes to COURSE, executes query. | Observed code; confirm login identity meaning and first-load behavior. |
| F1-TR-02 | `QAFE_FORM1_fmb.xml`, block COURSE | `PRE-INSERT` | Current COURSE values and global user | Sets created/modified dates to `SYSDATE`, created/modified users to `:global.user_id`, and `COURSE_NO` from `COURSE_NO_SEQ.NEXTVAL`. | Observed code; test generated key/audit fields and duplicate/sequence boundary. |
| F1-TR-03 | `QAFE_FORM1_fmb.xml`, block COURSE | `PRE-UPDATE` | Current COURSE values and global user | Sets modified date to `SYSDATE` and modifier to global user. | Observed code; test audit update and transaction result. |
| F2-TR-01 | `QAFE_FORM2_fmb.xml`, FormModule `QAFE_FORM2` | `WHEN-NEW-FORM-INSTANCE` | None shown | Sets user global to `QAFE`, navigates to INSTRUCTOR, executes query, shows CANVAS1. | Observed code; confirm identity and initial page. |
| F2-TR-02 | `QAFE_FORM2_fmb.xml`, block INSTRUCTOR | `PRE-INSERT` | Current INSTRUCTOR values and global user | Uses `INSTRUCTOR_ID_SEQ.NEXTVAL`; sets created/modified users and dates. | Observed code; compare with SQL view trigger behavior. |
| F2-TR-03 | `QAFE_FORM2_fmb.xml`, block INSTRUCTOR | `PRE-UPDATE` | Current INSTRUCTOR values and global user | Sets modified user and date. | Observed code; test audit update. |
| F2-TR-04 | `QAFE_FORM2_fmb.xml`, item INSTRUCTOR.ZIP | `WHEN-MOUSE-DOUBLECLICK` | ZIP item | Calls `DO_KEY('LIST_VALUES')`. | Observed code; actual LOV invocation and keyboard behavior to verify. |
| F2-TR-05 | `QAFE_FORM2_fmb.xml`, item PUSH_BUTTON1 | `WHEN-BUTTON-PRESSED` | Button action | Goes to COURSE, executes query, shows WINDOW2. | Observed code; test navigation and query errors. |
| F2-TR-06 | `QAFE_FORM2_fmb.xml`, item PUSH_BUTTON2 | `WHEN-BUTTON-PRESSED` | Button action | Goes to STUDENT, executes query, shows WINDOW3. | Observed code; test navigation. |
| F2-TR-07 | `QAFE_FORM2_fmb.xml`, item PUSH_BUTTON3 | `WHEN-BUTTON-PRESSED` | Button action | Hides WINDOW2 and moves cursor to INSTRUCTOR.FIRST_NAME. | Observed code; test focus and window state. |
| F2-TR-08 | `QAFE_FORM2_fmb.xml`, item PUSH_BUTTON4 | `WHEN-BUTTON-PRESSED` | Button action | Hides WINDOW3 and moves cursor to INSTRUCTOR.FIRST_NAME. | Observed code; test focus and window state. |
| F2-TR-09 | `QAFE_FORM2_fmb.xml`, block COURSE | `ON-POPULATE-DETAILS` | Current COURSE record and SECTION relation | Queries SECTION details through `COURSE_SECTION`; if cursor moved, returns to original item and checks package failure. | Observed Forms default relation code; test detail refresh and no-detail state. |
| F2-TR-10 | `QAFE_FORM2_fmb.xml`, block COURSE | `ON-CHECK-DELETE-MASTER` | COURSE_NO and SECTION rows | Checks for matching SECTION; if found, displays “Cannot delete master record when matching detail records exist.” and raises `FORM_TRIGGER_FAILURE`. | Observed code; test parent delete with/without details and concurrent child insert. |
| F2-TR-11 | `QAFE_FORM2_fmb.xml`, FormModule | `ON-CLEAR-DETAILS` | Relation state | Calls `CLEAR_ALL_MASTER_DETAILS`. | Observed code; confirm cancel/commit prompts when details changed. |
| F3-TR-01 | `QAFE_FORM3_fmb.xml`, FormModule | `WHEN-NEW-FORM-INSTANCE` | None shown | Sets user global to `Qafe`, goes to COURSE, executes query. | Observed code; confirm identity and initial state. |
| F3-TR-02 | `QAFE_FORM3_fmb.xml`, block SECTION | `WHEN-NEW-BLOCK-INSTANCE` | SECTION block | Executes query. | Observed code; confirm query criteria and timing. |
| F3-TR-03 | `QAFE_FORM3_fmb.xml`, item SECTION.COURSE_NO | `WHEN-VALIDATE-ITEM` | Entered course number | Queries COURSE; on no match shows “This course does not exist in the database.” and raises `FORM_TRIGGER_FAILURE`. The fetch target in the exported code is `:course.course_no`, not the SECTION item. | Observed code with suspicious target; do not “fix” until owner confirms intended behavior. Test existing/missing course and side effects. |
| F3-TR-04 | `QAFE_FORM3_fmb.xml`, item COURSE.COST | `WHEN-VALIDATE-ITEM` | Entered cost | If cost `< 5`, shows “Course cost has to be greater than 5” and raises failure. Exactly 5 is not rejected by this condition. | Observed code; boundary test 4.99, 5, 5.01; clarify whether message or predicate is authoritative. |
| F3-TR-05 | `QAFE_FORM3_fmb.xml`, block COURSE | `POST-QUERY` | Current course number | Counts sections for course and enrollment rows joined through SECTION into display items `SECTIONCOUNT` and `STUDENTCOUNT`. | Observed SQL; test zero/many sections and enrollments, and consistency under concurrent changes. |
| F3-TR-06 | `QAFE_FORM3_fmb.xml`, item PUSH_BUTTON_WINDOW | `WHEN-BUTTON-PRESSED` | Button action | Shows WINDOW2, goes to SECTION, and item SECTION_ID. | Observed code; test navigation and return. |
| F3-TR-07 | `QAFE_FORM3_fmb.xml`, item HIDESTUDENTCOUNT | `WHEN-BUTTON-PRESSED` | Current visibility | Toggles visibility of STUDENTCOUNT with `GET_ITEM_PROPERTY`/`SET_ITEM_PROPERTY`. | Observed code; test both states and accessibility equivalent. |
| F3-TR-08 | `QAFE_FORM3_fmb.xml`, item PUSH_BUTTON_CLOSE → program unit GO_BACK_TO_HOME_SCREEN | `WHEN-BUTTON-PRESSED` | Button action | Hides WINDOW2 and navigates to COURSE.COURSE_NO. | Observed code; test unsaved changes and focus after return. |

### Forms2XML Trigger Inventory Check

A structural count of the exported XML confirms 3 triggers in QAFE_FORM1, 11 in QAFE_FORM2, and 8 in QAFE_FORM3. Each exported trigger is represented by the corresponding F1-TR, F2-TR, or F3-TR row above. This verifies inventory coverage only; it does not establish Forms runtime timing or resolve the open Form 3 decisions R-06/R-07.

### QAFE_FORM1 Event and Validation Coverage

The Forms2XML inventory for `QAFE_FORM1` reports three triggers: FormModule `WHEN-NEW-FORM-INSTANCE`, COURSE `PRE-INSERT` (`F1-TR-02`), and COURSE `PRE-UPDATE` (`F1-TR-03`). No COURSE `WHEN-VALIDATE-ITEM`, `WHEN-VALIDATE-RECORD`, `PRE-DELETE`, or FormModule `ON-ERROR` trigger is present in this module export. This is an XML source inventory, not proof of runtime behavior. The COURSE NOT NULL, PK, and prerequisite FK constraints remain enforced by the database; see `tests/acceptance/US4-validation.md` for the mapped cases and proof statuses.

## Rules from SQL

| ID | Source | Condition | Effect / message | Status / target test |
|---|---|---|---|---|
| DB-TR-01 | `script/student-db-script.sql`, `TRIGGER_STUDENT_BEFORE_INSERT` | `:NEW.FIRST_NAME IS NULL` | Raises application error `-20101` with text requiring FIRST_NAME. | Observed SQL; test insert null, empty-string semantics on Oracle, and no partial row. |
| DB-TR-02 | `script/student-db-script.sql`, `TRIGGER_STUDENT_BEFORE_UPDATE` | `:NEW.FIRST_NAME IS NULL` | Raises application error `-20101`. | Observed SQL; test update null and persisted state. |
| DB-PL-01 | `ADF_EX10_01_TRIGGERS.STUDENT_POSTQ` | POST-QUERY helper called with student ZIP | Selects city/state from ZIPCODE into object fields. | Observed package body; Forms call site and exception if ZIP absent require export/runtime confirmation. |
| DB-PL-02 | `ADF_EX10_01_TRIGGERS.STUDENT_ZIP_WVI` | ZIP lookup returns no row | Sets `P_STUDENT.MESSAGE` to `THIS ZIPCODE DOES NOT EXIST IN THE DATABASE.` and returns. | Observed package body; exact UI message timing and caller behavior to confirm. |
| DB-VW-01 | `V_QAFE_FORM1_COURSE_TRG` | INSERT / UPDATE / DELETE | INSERT writes COURSE. UPDATE and DELETE predicates are `WHERE 1 = 0`, affecting no rows. | Observed SQL; owner chose CRUD as target, so treat no-op branches as a discrepancy to resolve and regression-test. |
| DB-VW-02 | `V_QAFE_FORM2_INSTRUCTOR_TRG` | INSERT / UPDATE / DELETE | INSERT writes INSTRUCTOR. UPDATE and DELETE predicates are `WHERE 1 = 0`. | Observed SQL; same CRUD discrepancy gate. |
| DB-VW-03 | `V_QAFE_FORM2_STUDENT_TRG` | INSERT / UPDATE / DELETE | INSERT writes STUDENT. UPDATE and DELETE predicates are `WHERE 1 = 0`. | Observed SQL; same CRUD discrepancy gate. |
| DB-VW-04 | `V_EX10_01_STUDENT_TRG` | INSERT / UPDATE / DELETE | Writes STUDENT using student_id key. | Observed SQL; FMB binding is unconfirmed. |
| DB-VW-05 | `V_EX01_01_STUDENT_TRG` | INSERT / UPDATE / DELETE | References STUDENT_TEST, absent from declared table DDL; local load reported invalid view/trigger. | Observed inconsistency; do not map until dependency and caller are identified. |

## Forms Event Inventory Status

### QAFE_FORM2 Validation Caller Boundaries

- The Forms2XML export lists the INSTRUCTOR ZIP double-click trigger (`F2-TR-04`) that calls `DO_KEY('LIST_VALUES')`; the block exposes STUDENT with DML flags. No Form 2 `WHEN-VALIDATE-ITEM` trigger for `STUDENT.FIRST_NAME` or a Forms trigger invoking `STUDENT_ZIP_WVI`/`STUDENT_POSTQ` was identified in the reviewed trigger inventory.
- SQL source separately defines `TRIGGER_STUDENT_BEFORE_INSERT` and `TRIGGER_STUDENT_BEFORE_UPDATE` on the base STUDENT table. Both run before DML and reject null FIRST_NAME with error `-20101` and the message recorded in `tests/acceptance/US4-validation.md`. Whether Form 2 submits through these triggers is conditional on the effective block/view binding and runtime path; do not claim the UI behavior until verified.
- `ADF_EX10_01_TRIGGERS.STUDENT_POSTQ` selects CITY/STATE for a supplied ZIP. `STUDENT_ZIP_WVI` sets a message on missing ZIP and returns; it does not itself raise an exception. The Form 2 LOV maps ZIP only back to `INSTRUCTOR.ZIP`, while the package helpers reference a STUDENT object. Their relationship to Form 2 remains unknown.
- Form 2 has no approved personal-data read scope or write actor. Keep these rules as test design only; do not expose an APEX page or run the scenarios until the owner approves scope and sanitized fixtures.

Observed exported events are listed above. A complete event inventory still requires checking every event node in each XML, including any events beyond the summarized rows. The original specification’s requested events (WHEN-NEW-ITEM-INSTANCE, WHEN-VALIDATE-RECORD, POST-INSERT, POST-UPDATE, PRE-DELETE, KEY-COMMIT, ON-ERROR, and all others) must be explicitly recorded as present or absent per module from a systematic XML query before this analysis is marked complete.

No event-to-APEX equivalence is asserted. Candidate mappings and validation outcomes belong in `docs/migration-mapping.md` and `tests/acceptance/` after owner review.