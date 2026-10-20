# Data Model Baseline

**Source of truth for this inventory**: `script/student-db-script.sql` (example DDL), not a production schema export. Names and relationships below are observed in that script. Forms block bindings and unexpressed business relationships remain unverified until the three FMB modules are exported.

## Tables and columns

| Entity/table | Columns in the example DDL |
|---|---|
| `STUDENT.COURSE` | `COURSE_NO`, `DESCRIPTION`, `COST`, `PREREQUISITE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.SECTION` | `SECTION_ID`, `COURSE_NO`, `SECTION_NO`, `START_DATE_TIME`, `LOCATION`, `INSTRUCTOR_ID`, `CAPACITY`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.INSTRUCTOR` | `INSTRUCTOR_ID`, `SALUTATION`, `FIRST_NAME`, `LAST_NAME`, `STREET_ADDRESS`, `ZIP`, `PHONE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.STUDENT` | `STUDENT_ID`, `SALUTATION`, `FIRST_NAME`, `LAST_NAME`, `STREET_ADDRESS`, `ZIP`, `PHONE`, `EMPLOYER`, `REGISTRATION_DATE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.ZIPCODE` | `ZIP`, `CITY`, `STATE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.ENROLLMENT` | `STUDENT_ID`, `SECTION_ID`, `ENROLL_DATE`, `FINAL_GRADE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.GRADE` | `STUDENT_ID`, `SECTION_ID`, `GRADE_TYPE_CODE`, `GRADE_CODE_OCCURRENCE`, `NUMERIC_GRADE`, `COMMENTS`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.GRADE_TYPE` | `GRADE_TYPE_CODE`, `DESCRIPTION`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.GRADE_TYPE_WEIGHT` | `SECTION_ID`, `GRADE_TYPE_CODE`, `NUMBER_PER_SECTION`, `PERCENT_OF_FINAL_GRADE`, `DROP_LOWEST`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.GRADE_CONVERSION` | `LETTER_GRADE`, `GRADE_POINT`, `MAX_GRADE`, `MIN_GRADE`, `CREATED_BY`, `CREATED_DATE`, `MODIFIED_BY`, `MODIFIED_DATE` |
| `STUDENT.PS_TXN` | `ID`, `PARENTID`, `COLLID`, `CONTENT` (BLOB), `CREATION_DATE` |

Column types, lengths, nullability, defaults, and check constraints are defined in the source SQL and must be extracted into the detailed inventory before any schema change is planned. `PS_TXN` business use is unknown.

## Declared keys and relationships

| Constraint | Declared relationship / uniqueness |
|---|---|
| `CRSE_PK` | `COURSE(COURSE_NO)` primary key |
| `CRSE_CRSE_FK` | `COURSE(PREREQUISITE)` references `COURSE(COURSE_NO)` |
| `SECT_PK` | `SECTION(SECTION_ID)` primary key |
| `SECT_SECT2_UK` | `SECTION(SECTION_NO, COURSE_NO)` unique |
| `INST_PK` | `INSTRUCTOR(INSTRUCTOR_ID)` primary key |
| `STU_PK` | `STUDENT(STUDENT_ID)` primary key |
| `ZIP_PK` | `ZIPCODE(ZIP)` primary key |
| `INST_ZIP_FK` | `INSTRUCTOR(ZIP)` references `ZIPCODE(ZIP)` |
| `STU_ZIP_FK` | `STUDENT(ZIP)` references `ZIPCODE(ZIP)` |
| `ENR_PK` | `ENROLLMENT(STUDENT_ID, SECTION_ID)` primary key |
| `GR_PK` | `GRADE(STUDENT_ID, SECTION_ID, GRADE_TYPE_CODE, GRADE_CODE_OCCURRENCE)` primary key |
| `GR_ENR_FK` | `GRADE(STUDENT_ID, SECTION_ID)` references `ENROLLMENT(STUDENT_ID, SECTION_ID)` |
| `GRTW_PK` | `GRADE_TYPE_WEIGHT(SECTION_ID, GRADE_TYPE_CODE)` primary key |
| `GR_GRTW_FK` | `GRADE(SECTION_ID, GRADE_TYPE_CODE)` references `GRADE_TYPE_WEIGHT(SECTION_ID, GRADE_TYPE_CODE)` |
| `GRTYP_PK` | `GRADE_TYPE(GRADE_TYPE_CODE)` primary key |
| `GRCON_PK` | `GRADE_CONVERSION(LETTER_GRADE)` primary key |
| `PS_TXN_PK` | `PS_TXN(COLLID, ID)` primary key |

The script describes `SECTION.COURSE_NO`, `SECTION.INSTRUCTOR_ID`, and the `ENROLLMENT` references to `STUDENT`/`SECTION` in comments and business context, but does not declare those foreign keys. Do not silently infer them as enforced constraints.

## Views

- `V_QAFE_FORM1_COURSE`: projection of `COURSE`; used by the Form 1 demonstration per trigger comments, but exact FMB binding awaits export.
- `V_QAFE_FORM2_COURSE`: projection of `COURSE`.
- `V_QAFE_FORM2_INSTRUCTOR`: projection of `INSTRUCTOR`.
- `V_QAFE_FORM2_SECTION`: projection of `SECTION`.
- `V_QAFE_FORM2_STUDENT`: projection of `STUDENT`.
- `V_EX10_01_STUDENT`: projects `STUDENT`; `CITY`, `STATE`, and `EXIT` are literal `NULL` columns.
- `V_EX01_01_STUDENT`: references `STUDENT_TEST`, which is not declared among the 11 tables in this script; local load reported it invalid. Dependency and runtime use are unknown.

## Sequences and code objects

Sequences: `COURSE_NO_SEQ` (start 457), `INSTRUCTOR_ID_SEQ` (115), `PS_TXN_SEQ` (5401, increment 50), `SECTION_ID_SEQ` (169), `STUDENT_ID_SEQ` (401). Values reflect the example dump and must not be treated as production allocation state.

Object types: `ADF_EX10_01_STUDENT`, `ALERT`, `FORMS_SYSTEM`, `STUDENTOBJ`, `STUDENTOBJ_LIST`.

Packages: `ADF_EX10_01_TRIGGERS`, `STUDENTPKG`, and their bodies; the dump also contains a `STUDENT` package body with compilation problems in the local load. Package usage by individual forms is not proven without FMB exports.

## Rules and DML triggers visible in SQL

- `TRIGGER_STUDENT_BEFORE_INSERT` and `TRIGGER_STUDENT_BEFORE_UPDATE` reject a null `FIRST_NAME` with application error `-20101`.
- `ADF_EX10_01_TRIGGERS.STUDENT_POSTQ` reads `CITY` and `STATE` from `ZIPCODE` by `ZIP`.
- `ADF_EX10_01_TRIGGERS.STUDENT_ZIP_WVI` sets the message `THIS ZIPCODE DOES NOT EXIST IN THE DATABASE.` when the lookup finds no ZIP.
- `V_QAFE_FORM1_COURSE_TRG`, `V_QAFE_FORM2_INSTRUCTOR_TRG`, and `V_QAFE_FORM2_STUDENT_TRG` contain INSERT branches to base tables; their UPDATE/DELETE branches use `WHERE 1 = 0`, so those branches affect no rows as written.
- `V_EX10_01_STUDENT_TRG` has INSERT/UPDATE/DELETE branches against `STUDENT` with a student ID predicate.
- `V_EX01_01_STUDENT_TRG` targets the missing `STUDENT_TEST` object and is not a reliable migration source until its dependency is resolved.

## Forms block bindings from XML

The bindings below are observed in the Forms2XML exports. DML flags indicate Forms block metadata, not successful database persistence; the SQL `INSTEAD OF` triggers described above contain no-op UPDATE/DELETE branches for several views.

| Module | Block | Query source | Insert / update / delete flags | Notes |
|---|---|---|---|---|
| `QAFE_FORM1` | `COURSE` | `course` | true / true / true | Eight database items. `COURSE_NO` has an empty exported `ColumnName` property; verify item binding. |
| `QAFE_FORM2` | `INSTRUCTOR` | `INSTRUCTOR` | true / true / true | Eleven database items; contains ZIP LOV invocation and pre-insert/pre-update audit logic. |
| `QAFE_FORM2` | `COURSE` | `COURSE` | false / false / false | Read-only block; master of `COURSE_SECTION`. |
| `QAFE_FORM2` | `SECTION` | `SECTION` | false / false / false | Read-only detail block for COURSE. |
| `QAFE_FORM2` | `STUDENT` | `STUDENT` | true / true / true | Thirteen database items plus navigation button. |
| `QAFE_FORM3` | `COURSE` | `COURSE` | true / true / true | Has unbound `SECTIONCOUNT` and `STUDENTCOUNT` display items and a visibility toggle. |
| `QAFE_FORM3` | `SECTION` | `SECTION` | true / true / true | `COURSE_NO` has an item validation trigger; block executes a query on entry. |
| `QAFE_FORM3` | `SUB_BLOCK` | none shown | true / true / true in XML metadata | Contains a close button; database-block behavior and exact purpose require Builder review. |

Other exported components include Form 2 windows `WINDOW1/2/3`, canvases `CANVAS1/2/3`, ZIP LOV/record group, and a COURSE-to-SECTION relation; Form 3 has two windows, two canvases, and a close-screen program unit. Exact layout and commit/rollback behavior still require Builder/runtime review.