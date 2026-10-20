# Oracle Forms Inventory

**Evidence basis**: Oracle Forms2XML 14.1.2 exports in `docs/forms-exports/` (`DUMP=ALL`, `USE_PROPERTY_IDS=YES`). The three source `.fmb` files were hashed before and after export and remained unchanged. Property names and code below are observed in XML; the README remains descriptive rather than authoritative for runtime behavior.

## Source and Export Register

| Module | Source SHA-256 | Export XML | Export SHA-256 | Bytes | Review |
|---|---|---|---|---:|---|
| `QAFE_FORM1.fmb` | `4C9EBAC6E730FBD502A65CE2A58EC33287E4B604929979F18D69E610BFBBF3D6` | `docs/forms-exports/QAFE_FORM1_fmb.xml` | `440936BBCE47DC3958E20A5F963768B23B855A9767983B73C2815C7A5E4CB045` | 70,721 | XML parsed; component inventory below |
| `QAFE_FORM2.fmb` | `43DB95278C9D996DE602A1D0533609B7115FF502D585D6642595834224D3CDCA` | `docs/forms-exports/QAFE_FORM2_fmb.xml` | `EC86B66ABBBD3A61A2A37DC4F5B2D03436E4F9D225C37DD564E96BEA62487B69` | 418,921 | XML parsed; component inventory below |
| `QAFE_FORM3.fmb` | `2CD4FF34498036B2ED10564677394ECABA583CCB5BB31CA2CE0A8BBBF2AF4120` | `docs/forms-exports/QAFE_FORM3_fmb.xml` | `512216A7B0F8079DCFDD572F234CA9554E01EF1FFF148B71A3CECC40F96BE5AA` | 200,979 | XML parsed; component inventory below |

The converter reports that `DUMP=ALL` XML cannot be converted back into an FMB. These XML files are analysis evidence, not editable replacements for the original modules. The utility emitted them beside each source; they were moved into the evidence directory without overwriting an existing file.

## Form 1: `QAFE_FORM1`

**Observed components**: one database block `COURSE`, query source `course`, one canvas `COURSE`, one window `COURSES` titled “Courses”, eight database items, and three triggers. The block XML sets insert/update/delete allowed to `true`.

**Items**: `PREREQUISITE`, `COURSE_NO`, `DESCRIPTION`, `COST`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE`. The exported `COURSE_NO` item has an empty `ColumnName` property despite being displayed as Course No.; verify key binding in Builder/runtime.

**Triggers**: form `WHEN-NEW-FORM-INSTANCE`; block `PRE-INSERT`; block `PRE-UPDATE`. See `docs/trigger-analysis.md`.

**README claim**: simple form, query mode, CRUD. The export confirms block-level DML flags, not that every branch successfully persists; SQL trigger evidence shows UPDATE/DELETE no-ops on the corresponding view trigger.

## Form 2: `QAFE_FORM2`

**Observed components**: four database blocks; three canvases (`CANVAS1`, `CANVAS2`, `CANVAS3`); three windows (`WINDOW1` Instructors, `WINDOW2` Courses, `WINDOW3` Students); one LOV `ZIP_LOV`; one record group `ZIP_RG`; one relation `COURSE_SECTION`; three program units; eleven triggers.

| Block | Query source | Insert / update / delete allowed | Exported database items (non-database buttons omitted) |
|---|---|---|---|
| `INSTRUCTOR` | `INSTRUCTOR` | true / true / true | `CREATED_BY`, `FIRST_NAME`, `LAST_NAME`, `INSTRUCTOR_ID`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE`, `SALUTATION`, `STREET_ADDRESS`, `ZIP`, `PHONE` |
| `COURSE` | `COURSE` | false / false / false | `COURSE_NO`, `DESCRIPTION`, `COST`, `PREREQUISITE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `SECTION` | `SECTION` | false / false / false | `SECTION_ID`, `COURSE_NO`, `SECTION_NO`, `START_DATE_TIME`, `LOCATION`, `INSTRUCTOR_ID`, `CAPACITY`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT` | `STUDENT` | true / true / true | `STUDENT_ID`, `SALUTATION`, `REGISTRATION_DATE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE`, `FIRST_NAME`, `LAST_NAME`, `STREET_ADDRESS`, `ZIP`, `PHONE`, `EMPLOYER` |

The relation is named `COURSE_SECTION`, with detail block `SECTION` and join condition `SECTION.COURSE_NO = COURSE.COURSE_NO`. The XML exposes default relation triggers `ON-POPULATE-DETAILS` and `ON-CHECK-DELETE-MASTER` on COURSE.

`ZIP_LOV` is titled “Zip Codes” and uses `ZIP_RG`; record group query is `select zip, city, state from zipcode`. The ZIP column returns to `INSTRUCTOR.ZIP`; CITY and STATE have no return item in the XML. A double-click on `INSTRUCTOR.ZIP` invokes `DO_KEY('LIST_VALUES')`.

Program units: `CHECK_PACKAGE_FAILURE`, `QUERY_MASTER_DETAILS`, `CLEAR_ALL_MASTER_DETAILS`. Windows/canvases are linked by names in XML; exact visual layout and runtime navigation must be reviewed in Builder.

**README claim**: a data grid with overflow and ZIP LOV, another grid, a master-detail relation, query mode on the main master and data grid, and CRUD. XML shows COURSE and SECTION blocks are read-only while INSTRUCTOR and STUDENT have DML flags enabled. Confirm actual user-facing CRUD scope with owner before design.

## Form 3: `QAFE_FORM3`

**Observed components**: database blocks `COURSE` and `SECTION`, plus `SUB_BLOCK` with no query source; canvases `CANVAS10` and `CANVAS2`; windows `WINDOW1` and `WINDOW2`; one program unit `GO_BACK_TO_HOME_SCREEN`; eight triggers.

| Block | Query source | Insert / update / delete allowed | Notable items |
|---|---|---|---|
| `COURSE` | `COURSE` | true / true / true | Course columns; display-only/unbound `SECTIONCOUNT`, `STUDENTCOUNT`; buttons `PUSH_BUTTON_WINDOW`, `HIDESTUDENTCOUNT` |
| `SECTION` | `SECTION` | true / true / true | Section columns; `COURSE_NO` has `WHEN-VALIDATE-ITEM`; block has `WHEN-NEW-BLOCK-INSTANCE` |
| `SUB_BLOCK` | empty | true / true / true in XML metadata | `PUSH_BUTTON_CLOSE`; exact non-database purpose to confirm |

`COURSE` has `POST-QUERY` count queries for sections and enrolled students. `PUSH_BUTTON_WINDOW` opens WINDOW2 and navigates to SECTION; `HIDESTUDENTCOUNT` toggles the visibility of `STUDENTCOUNT`. `PUSH_BUTTON_CLOSE` invokes `GO_BACK_TO_HOME_SCREEN`, which hides WINDOW2 and returns to `COURSE.COURSE_NO`.

**README claim**: a complex one-window form with text/date/number fields, simple and database validation, post-query using a database View Object, triggers/program units, SHOW/HIDE_WINDOW and item-property access. The XML contains COURSE/SECTION blocks and two windows; the View Object terminology and UI structure need reconciliation with the actual exported properties and README.

## Missing or Unverified Dependencies

- Repository source contains no `.pll`, `.plx`, `.mmb`, `.mmx`, `.olb`, `.fmt`, prior FMB XML, deployment config, or screenshots.
- SQL names `STUDENT_TEST` in `V_EX01_01_STUDENT` and `V_EX01_01_STUDENT_TRG`; its table definition is absent from the script and its form usage is not established.
- XML contains no attributes matching the searched role/privilege/security property names. This is not proof that there is no external authentication, database privilege, or deployment security policy.
- Verify attached libraries, menus, external calls, canvas/window presentation, all item properties, triggers not summarized here, and forms-level failure behavior with a complete XML review and Builder inspection before declaring inventory complete.