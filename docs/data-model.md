# Data Model and Form Bindings

**Evidence**: `script/student-db-script.sql` and the parsed Forms2XML files in `docs/forms-exports/`. This is an example schema, not a production database extract. Relationships without declared constraints are not treated as enforced foreign keys.

## Tables

| Table | Columns from example DDL | Declared primary/unique keys |
|---|---|---|
| `COURSE` | COURSE_NO, DESCRIPTION, COST, PREREQUISITE, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | COURSE_NO; prerequisite self-reference |
| `SECTION` | SECTION_ID, COURSE_NO, SECTION_NO, START_DATE_TIME, LOCATION, INSTRUCTOR_ID, CAPACITY, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | SECTION_ID; unique SECTION_NO + COURSE_NO |
| `INSTRUCTOR` | INSTRUCTOR_ID, SALUTATION, FIRST_NAME, LAST_NAME, STREET_ADDRESS, ZIP, PHONE, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | INSTRUCTOR_ID; ZIP references ZIPCODE |
| `STUDENT` | STUDENT_ID, SALUTATION, FIRST_NAME, LAST_NAME, STREET_ADDRESS, ZIP, PHONE, EMPLOYER, REGISTRATION_DATE, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | STUDENT_ID; ZIP references ZIPCODE |
| `ZIPCODE` | ZIP, CITY, STATE, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | ZIP |
| `ENROLLMENT` | STUDENT_ID, SECTION_ID, ENROLL_DATE, FINAL_GRADE, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | STUDENT_ID + SECTION_ID |
| `GRADE` | STUDENT_ID, SECTION_ID, GRADE_TYPE_CODE, GRADE_CODE_OCCURRENCE, NUMERIC_GRADE, COMMENTS, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | STUDENT_ID + SECTION_ID + GRADE_TYPE_CODE + GRADE_CODE_OCCURRENCE |
| `GRADE_TYPE` | GRADE_TYPE_CODE, DESCRIPTION, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | GRADE_TYPE_CODE |
| `GRADE_TYPE_WEIGHT` | SECTION_ID, GRADE_TYPE_CODE, NUMBER_PER_SECTION, PERCENT_OF_FINAL_GRADE, DROP_LOWEST, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | SECTION_ID + GRADE_TYPE_CODE |
| `GRADE_CONVERSION` | LETTER_GRADE, GRADE_POINT, MAX_GRADE, MIN_GRADE, CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE | LETTER_GRADE |
| `PS_TXN` | ID, PARENTID, COLLID, CONTENT BLOB, CREATION_DATE | COLLID + ID |

The script declares `GRADE` foreign keys to `ENROLLMENT` and `GRADE_TYPE_WEIGHT`; `INSTRUCTOR.ZIP` and `STUDENT.ZIP` reference `ZIPCODE`; `COURSE.PREREQUISITE` is a self-reference. It does not declare FKs from SECTION to COURSE/INSTRUCTOR or ENROLLMENT to STUDENT/SECTION despite descriptive comments. Confirm intended integrity rules with the owner.

## Views and sequences

Views: `V_EX01_01_STUDENT`, `V_EX10_01_STUDENT`, `V_QAFE_FORM1_COURSE`, `V_QAFE_FORM2_COURSE`, `V_QAFE_FORM2_INSTRUCTOR`, `V_QAFE_FORM2_SECTION`, `V_QAFE_FORM2_STUDENT`.

Sequences: `COURSE_NO_SEQ`, `INSTRUCTOR_ID_SEQ`, `PS_TXN_SEQ`, `SECTION_ID_SEQ`, `STUDENT_ID_SEQ`. The values in the dump are examples and are not production sequence baselines.

`V_EX01_01_STUDENT` selects `STUDENT_TEST`, which is not declared in the supplied DDL and was invalid in the local example load. `V_EX10_01_STUDENT` projects CITY, STATE, and EXIT as NULL. Several INSERT statements in the original SQL target these virtual columns and the load reported ORA-01733.

## Types and packages

Object types: `ADF_EX10_01_STUDENT` (student values plus message), `ALERT`, `FORMS_SYSTEM`, `STUDENTOBJ` (student ID/name/phone), and `STUDENTOBJ_LIST` (collection of STUDENTOBJ).

Packages in the script: `ADF_EX10_01_TRIGGERS` (POST-QUERY, ZIP validation, EXIT button helpers), `STUDENTPKG` (returns a collection of student IDs/names/phones), and a `STUDENT` package body whose local compilation reported errors. The package/body and Forms call-site relationship is not fully confirmed; do not assume the broken body is required by the three modules.

## Forms block bindings observed in XML

| Module | Block | Query source | DML flags (I/U/D) | Notes |
|---|---|---|---|---|
| Form 1 | COURSE | `course` | true/true/true | Eight items; COURSE_NO ColumnName is empty in XML and needs Builder review. |
| Form 2 | INSTRUCTOR | INSTRUCTOR | true/true/true | ZIP item invokes ZIP_LOV; PRE-INSERT and PRE-UPDATE set audit values. |
| Form 2 | COURSE | COURSE | false/false/false | Master block for COURSE_SECTION. |
| Form 2 | SECTION | SECTION | false/false/false | Detail block; join SECTION.COURSE_NO = COURSE.COURSE_NO. |
| Form 2 | STUDENT | STUDENT | true/true/true | Student profile block. |
| Form 3 | COURSE | COURSE | true/true/true | Includes unbound SECTIONCOUNT and STUDENTCOUNT display items. |
| Form 3 | SECTION | SECTION | true/true/true | COURSE_NO validation and query on block entry. |
| Form 3 | SUB_BLOCK | No query source shown | XML flags true/true/true | Contains a close button; database-block semantics are unverified. |

Forms block flags do not prove successful persistence. SQL view triggers for Form 1 COURSE and Form 2 INSTRUCTOR/STUDENT contain no-op UPDATE/DELETE predicates (`WHERE 1 = 0`). For the owner-approved local Form 2 target, pages 8/10 use guarded base-table DML; the legacy triggers remain unchanged. Runtime persistence and rollback still require acceptance testing.

