# US3 CRUD Acceptance Record: QAFE_FORM1

**Feature**: `001-forms-apex-migration`  
**Scope**: COURSE create, update, and delete behavior for the QAFE_FORM1 slice.  
**Status**: The approved one-fixture local CRUD run passed for create, update, delete, and duplicate-key rejection on 2026-10-20. The test harness is now excluded from runtime; no ongoing write authorization remains.  
**Sources**: `F1-TR-02`, `F1-TR-03`, `DB-VW-01`; `docs/trigger-analysis.md`; `script/student-db-script.sql`.  
**Gate**: T020 owner sign-off is recorded below. The owner separately authorized one disposable fixture operation by `QAFE_FORMS_BUILDER`; the fixture was deleted after verification. This was temporary test permission, not ongoing write authorization.

## Preconditions

- Use only the disposable COURSE fixture marked `QAFE CRUD TEST - QAFE_FORMS_BUILDER` in the isolated `QAFE_CLEAN` PDB.
- Do not update or delete the approved preview rows 454, 455, or 456.
- Use a test actor with an explicitly approved write grant. Until then, create, update, and delete remain denied.
- Capture the fixture row and audit values before each operation; compare persisted state after both success and rejection.
- Never run these cases against the legacy source schema or production data.

## Scenarios

| ID | Source / operation | Preconditions and action | Expected screen/result and persisted state | Actual result / status |
|---|---|---|---|---|
| F1-CRUD-01 | `F1-TR-02`, create COURSE | As `QAFE_FORMS_BUILDER`, submit the test harness form with cost 15. | Exactly one row is persisted; `COURSE_NO` is generated; created/modified audit values use the Builder identity and current timestamp; the row can be queried again. | PASS, 2026-10-20: created COURSE 457 with marker `QAFE CRUD TEST - QAFE_FORMS_BUILDER`, cost 15, and both audit identities set to `QAFE_FORMS_BUILDER`. Read-back confirmed the row. Sequence value 457 was consumed and was not rolled back. |
| F1-CRUD-02 | COURSE primary-key constraint | In `QAFE_CLEAN`, attempt an isolated direct insert with duplicate `COURSE_NO=454`, catch the expected constraint error, roll back, and verify persisted state. | The insert is rejected; no duplicate marker row is persisted; COURSE 454 remains unchanged. | PASS, 2026-10-20: enabled PK `CRSE_PK` raised `DUP_VAL_ON_INDEX`; rollback completed; duplicate marker count was 0; COURSE 454 remained English Grammar/30. |
| F1-CRUD-03 | `F1-TR-03`, update COURSE | Change the fixture cost from 15 to 25; retain its key, marker, and creation audit fields. | Exactly the fixture row changes; creation audit stays unchanged; modification audit reflects the approved actor/time; unrelated rows remain unchanged. | PASS, 2026-10-20: COURSE 457 cost changed 15 to 25; `CREATED_BY`/`CREATED_DATE` remained unchanged; `MODIFIED_BY` was `QAFE_FORMS_BUILDER` and `MODIFIED_DATE` advanced. |
| F1-CRUD-04 | Delete COURSE | Request deletion of fixture COURSE 457 and query the marker again. | Exactly the selected fixture row is removed; no unrelated row changes. | PASS, 2026-10-20: deletion succeeded and the marker count returned 0. Courses 454/455/456 retained their baseline values. |
| F1-CRUD-05 | Default-deny writes after test | After cleanup, request page 6 directly and inspect application page 4. | The test harness is unavailable in runtime; the catalogue remains read-only and no ongoing write access is granted. | PASS, 2026-10-20: direct request to page 6 returned `APEX.PAGE.NOT_FOUND` after Build Option was set to Commented Out and Page Access Protection to No URL Access. Page 4 remains an Interactive Report without a form or DML process. |

## Evidence and Open Decisions

- **T020 owner decision, 2026-10-20**: treat the Form 1 view trigger's UPDATE/DELETE `WHERE 1 = 0` predicates as defects; the APEX CRUD target must persist successful changes. This decision does not grant write authorization or approve a fixture.
- **Temporary test authorization, 2026-10-20**: the owner authorized `QAFE_FORMS_BUILDER` to create/update/delete one marked COURSE fixture in `QAFE_CLEAN`, then clean it up. This authorization expired after the test; no general or ongoing write grant was made.
- The export includes page 6 `Course CRUD Test Harness`, a custom PL/SQL process guarded by the Builder-only authorization scheme, a single-fixture row predicate, and server-side ownership/row-count checks. The page is now excluded from runtime and has No URL Access; the page 4 catalogue remains read-only.
- Forms XML `PRE-INSERT` assigns `COURSE_NO_SEQ.NEXTVAL`, created/modified dates, and created/modified users from `:global.user_id`. Forms XML `PRE-UPDATE` refreshes the modified date/user. This is source evidence, not a successful persistence test.
- The SQL view trigger `V_QAFE_FORM1_COURSE_TRG` inserts into COURSE, but UPDATE and DELETE predicates are `WHERE 1 = 0`. The target requirement is CRUD, while the implementation must not present a no-op as a successful write.
- The duplicate-key negative case passed. Unauthorized-user testing and injected transaction-failure/rollback cases were not run. No ongoing write permission is approved.
- Exact Forms runtime equivalence, sequence behavior under concurrent inserts, and production audit identity mapping remain unverified.