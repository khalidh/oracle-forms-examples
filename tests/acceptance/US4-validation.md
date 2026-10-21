# US4 Validation Acceptance Record: QAFE_FORM1

**Feature**: `001-forms-apex-migration`  
**Scope**: COURSE validation evidence for QAFE_FORM1 and source-backed FIRST_NAME/ZIP validation cases relevant to QAFE_FORM2.  
**Status**: Form 1 and Form 2 validation evidence is recorded; selected runtime cases passed. On 2026-10-21, the approved temporary Form 3 harness verified both owner-decided validation cases; no production Form 3 page was implemented.
**Sources**: `F1-TR-02`, `F1-TR-03`, `F2-TR-04`, `DB-TR-01`, `DB-TR-02`, `DB-PL-01`, `DB-PL-02`, `DB-VW-01`; `script/student-db-script.sql`; `docs/data-model.md`.  
**Boundary**: The temporary Form 1 write authorization has expired. Separate ongoing authorization remains active only for local `QAFE_FORMS_BUILDER` CRUD on INSTRUCTOR/STUDENT in `QAFE_CLEAN`, using synthetic fixtures; it does not authorize Form 1 writes, legacy-PDB access, or production access.

## Observed Validation Rules

The Forms2XML export contains `WHEN-NEW-FORM-INSTANCE`, COURSE `PRE-INSERT`, and COURSE `PRE-UPDATE`; no Form 1 `WHEN-VALIDATE-ITEM`, `WHEN-VALIDATE-RECORD`, or `ON-ERROR` trigger was found in the inventory. PRE-INSERT supplies `COURSE_NO_SEQ.NEXTVAL` and audit values; PRE-UPDATE refreshes modification audit values. This is source evidence, not proof of Forms runtime timing.

The `STUDENT.COURSE` table has enabled, validated constraints for non-null COURSE_NO, DESCRIPTION, CREATED_BY, CREATED_DATE, MODIFIED_BY, and MODIFIED_DATE; primary key `CRSE_PK`; and prerequisite self-FK `CRSE_CRSE_FK`. No Form 1 cost range rule is declared by the reviewed export or DDL; do not invent one. The target process writes directly to COURSE so database constraints remain authoritative.

## Scenarios

| ID | Source / rule | Action | Expected result / persisted state | Actual result / status |
|---|---|---|---|---|
| F1-VAL-01 | `F1-TR-02`, valid insert | Create the single marked fixture through the guarded harness. | Generated key and audit values satisfy COURSE constraints; exactly one row can be read back. | PASS via `F1-CRUD-01`; fixture later removed. |
| F1-VAL-02 | `CRSE_DESCRIPTION_NNULL` | With fresh write approval, attempt an insert that omits DESCRIPTION using a disposable fixture only. | Database rejects the insert; no row or partial audit values persist; UI reports failure rather than success. | Defined; not run. No further write authorization. |
| F1-VAL-03 | `CRSE_PK` | Attempt duplicate COURSE_NO 454, catch the constraint error, roll back, and read back the row. | Insert is rejected; no test row persists; COURSE 454 is unchanged. | PASS via `F1-CRUD-02`; `DUP_VAL_ON_INDEX`, duplicate marker count 0, COURSE 454 unchanged. |
| F1-VAL-04 | `CRSE_CRSE_FK` | With fresh write approval, attempt a marked fixture whose PREREQUISITE references a nonexistent COURSE_NO. | Database rejects the insert; no fixture row or partial audit values persist. | Defined; not run. No further write authorization. |
| F1-VAL-05 | `F1-TR-03`, update audit | Update the marked fixture cost and read back the row. | CREATED_BY/CREATED_DATE remain unchanged; MODIFIED_BY/MODIFIED_DATE change; unrelated rows remain unchanged. | PASS via `F1-CRUD-03`; fixture later removed. |
| F1-VAL-06 | Rollback on database error | Force a database-side failure during fixture DML using an isolated disposable row. | No partial row/audit change persists and the page reports failure. | Defined; not run. Requires a separately approved failure-injection method. |

## Scope Note

## QAFE_FORM2-Related SQL Validation Scenarios

The Form 2 export includes INSTRUCTOR and STUDENT blocks. `INSTRUCTOR.ZIP` invokes `ZIP_LOV`, and only ZIP maps back to the item. The supplied SQL has table-level STUDENT FIRST_NAME triggers and ZIP helper procedures, but their exact Forms caller/runtime mapping is not proven. Scenario outcomes below distinguish executed runtime cases from source-only expectations.

| ID | Source / rule | Action | Expected result / persisted state | Actual result / status |
|---|---|---|---|---|
| F2-VAL-01 | `DB-TR-01`, STUDENT insert | On an approved isolated STUDENT fixture, create a row with a non-null FIRST_NAME. | Insert succeeds only with other approved fields valid; one row persists and is queryable. | PASS: created synthetic STUDENT 401 through page 10 with non-null FIRST_NAME and valid ZIP; SQL read-back confirmed audit values. Fixture deleted after tests. |
| F2-VAL-02 | `DB-TR-01`, STUDENT insert | Attempt a STUDENT insert with `FIRST_NAME` null. | Database raises `-20101` with source message `FIRST_NAME must not be empty, please fill in. Value try to insert is: ...`; no row persists and the UI does not report success. | PASS: submitted page 10 Create with blank FIRST_NAME and marker LAST_NAME `COPILOT_NULL_INSERT_TEST`. APEX displayed `ORA-20101: FIRST_NAME must not be empty, please fill in. Value try to insert is:`. SQL confirmed STUDENT=0 and marker rows=0; no partial row persisted. |
| F2-VAL-03 | `DB-TR-02`, STUDENT update | On an approved isolated fixture, update another field while retaining a non-null FIRST_NAME. | Update succeeds; exactly the selected row changes; creation audit is retained and modification audit follows the approved identity/time rule. | PASS: page 10 changed the synthetic row's phone; SQL read-back confirmed `CREATED_DATE` remained unchanged and `MODIFIED_DATE` advanced. Fixture deleted after tests. |
| F2-VAL-04 | `DB-TR-02`, STUDENT update | Attempt to set `FIRST_NAME` null on an approved isolated fixture. | Database raises `-20101` with the source message; the prior row remains unchanged with no partial update. | PASS: page 10 displayed `ORA-20101: FIRST_NAME must not be empty...`; SQL read-back confirmed FIRST_NAME, phone, and modified audit remained unchanged. |
| F2-VAL-05 | `DB-PL-01` / `DB-PL-02`, ZIP helpers | With an approved ZIP fixture, test a present ZIP through the confirmed helper caller, then a missing ZIP. | Present ZIP can populate helper CITY/STATE; missing ZIP sets `THIS ZIPCODE DOES NOT EXIST IN THE DATABASE.` The helper itself returns rather than raising, so persistence rejection/rollback must be separately proven. | Defined from package source; caller and Forms timing unconfirmed; not run. The separate APEX ZIP LOV/FK path is covered by F2-VAL-06. |
| F2-VAL-06 | `F2-TR-04`, INSTRUCTOR ZIP LOV and FK | Open the populated ZIP select list, select a valid value, cancel without submit; then try an absent ZIP through a disposable marked instructor. | Valid ZIP can be selected; cancel persists nothing. An absent ZIP is rejected by the database FK and no partial instructor persists. CITY/STATE population is not assumed because the LOV XML defines no return mapping for them. | PASS, 2026-10-21: the select list had 147 options (blank plus 146 referenced ZIPs); selecting a valid option then cancelling created no row. A synthetic valid-ZIP instructor could be created and deleted. An injected absent ZIP `99998` returned `ORA-02291`; SQL confirmed no test row persisted. All fixtures were removed. |

## Scope Note

Form 2 runtime tests require a manual sign-in as `QAFE_FORMS_BUILDER`; no password belongs in this record. The ZIP fixture was removed after acceptance. Form 3 is limited to the owner-approved temporary validation/count harness: page 14 is disabled after testing, no user-facing Form 3 page is approved, and there is no ongoing Form 3 write authorization.

## QAFE_FORM3 Source Validation Scenarios

The exported Form 3 triggers provide the tested rules. Owner decisions on 2026-10-21 establish that `COST >= 5` is valid and that the SECTION.COURSE_NO trigger intentionally fetches into `COURSE.COURSE_NO`. F3-VAL-01 and F3-VAL-02 passed in the disabled temporary harness using SELECT-only processes; all fixtures were removed. Never change preview courses 454-456.

| ID | Source / rule | Action | Source-observed result / decision needed | Actual result / status |
|---|---|---|---|---|
| F3-VAL-01 | `F3-TR-04`, `COURSE.COST WHEN-VALIDATE-ITEM` | In the temporary Form 3 harness, submit costs 4.99, 5, and 5.01. | Owner decision: reject `< 5`; accept 5 and higher. Validation is server-side and does not write COURSE. | PASS, 2026-10-21: 4.99 displayed “Course cost must be at least 5.”; 5 and 5.01 were accepted. The harness has no COURSE DML; COURSE 454/455/456 remained unchanged. |
| F3-VAL-02 | `F3-TR-03`, `SECTION.COURSE_NO WHEN-VALIDATE-ITEM` | In the temporary Form 3 harness, validate existing 454 with target item initially 455, then missing 999999 with target initially 455. | Owner decision: preserve fetch into `COURSE.COURSE_NO`. Existing course mutates the target item; missing course displays the source message and fails without changing persisted data. | PASS, 2026-10-21: existing 454 changed the target item from 455 to 454. Missing 999999 displayed “This course does not exist in the database.” and left the target item at 455. The process is SELECT-only; COURSE remained unchanged. |