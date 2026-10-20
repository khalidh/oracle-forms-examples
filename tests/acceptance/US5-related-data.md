# US5 Related Data Acceptance Record: QAFE_FORM2

**Feature**: `001-forms-apex-migration`  
**Scope**: COURSE/SECTION master-detail, INSTRUCTOR ZIP lookup, and Form 2 navigation.  
**Status**: Owner approved local Form 2 data access and CRUD for editable blocks on 2026-10-20. Runtime CRUD, ZIP selection, and selected navigation cases passed with synthetic fixtures that were removed. COURSE-to-SECTION handoff/filter is implemented, and the empty-detail case passed for COURSE 454; a positive matching-section case and other related-data scenarios remain open.
**Sources**: `F2-TR-04` through `F2-TR-11`; `docs/forms-inventory.md`; `docs/trigger-analysis.md`; `script/student-db-script.sql`.  
**Approved local scope**: `QAFE_FORMS_BUILDER` may read the Form 2 block fields and local synthetic fixtures in `QAFE_CLEAN`. CRUD is authorized for INSTRUCTOR and STUDENT; COURSE and SECTION remain read-only because their Forms block flags are false/false/false. ZIPCODE may be read for the instructor ZIP LOV. No legacy-PDB or production access is authorized. Synthetic fixtures are to be removed after acceptance tests.

**Owner decision, 2026-10-20**: The earlier no-access decision is superseded. The owner now authorizes the local scope above and ongoing CRUD for the editable Form 2 blocks only.

## Preconditions

- Use only the approved `QAFE_FORMS_BUILDER` actor and the local `QAFE_CLEAN` PDB.
- Create only synthetic, disposable related-data fixtures in `QAFE_CLEAN`; document identifiers, relationships, and reset steps before seeding.
- Never test against the legacy PDB or production data. The COURSE preview rows 454/455/456 are not CRUD fixtures.
- Keep COURSE/SECTION read-only. Use base-table DML for INSTRUCTOR/STUDENT rather than the legacy views whose UPDATE/DELETE triggers use `WHERE 1 = 0`.

## Current APEX Snapshot

- Application 100 pages 7-10 are active, require `QAFE_FORMS_BUILDER_ONLY`, and require a checksum. Pages 8 and 10 use custom PL/SQL processes with process-level authorization and ownership predicates for update/delete.
- Page 7 INSTRUCTOR and page 9 STUDENT reports filter by `CREATED_BY = :APP_USER`. The runtime ZIP LOV showed `99999 - TESTVILLE, ZZ`; the temporary ZIP row was removed after testing.
- Pages 11 COURSE and 13 SECTION are read-only and Builder-only. Each Course Overview Description links to Section Overview and passes the hidden `P13_COURSE_NO`; page 13 filters `SECTION.COURSE_NO` and submits the item for report refresh. Runtime navigation passed `COURSE_NO=454` and returned the empty state, consistent with the empty SECTION table. A positive matching detail row has not been tested.
- The Instructors, Students, Course Overview, and Section Overview navigation entries are Builder-only. Runtime CRUD passed for synthetic INSTRUCTOR 115 and STUDENT 401; both rows were deleted. No test rows remain in INSTRUCTOR, STUDENT, or SECTION.

## Scenarios

| ID | Source / journey | Preconditions and action | Expected result | Actual result / status |
|---|---|---|---|---|
| F2-REL-01 | COURSE master to SECTION detail (`F2-TR-09`) | Select an existing COURSE from Course Overview and follow its Description link to Section Overview. | Show only rows joined by `SECTION.COURSE_NO = COURSE.COURSE_NO`; no unrelated details appear; selection changes do not mutate data. | PARTIAL: the runtime URL passed `P13_COURSE_NO=454` and the page returned the empty state. Filter configuration and handoff are verified; positive matching/no-unrelated row behavior remains untested because SECTION is empty and read-only. |
| F2-REL-02 | Empty and single detail results | Select a COURSE with zero, then one related SECTION. | The zero state is explicit; the single row appears once; query/navigation changes preserve the master context. | PARTIAL: the zero-detail case passed for COURSE 454. A one-detail fixture and transition remain untested; SECTION is read-only and no fixture was authorized. |
| F2-REL-03 | Grid overflow / edit affordance | Inspect the Forms grid and APEX candidate at narrow and wide viewports; attempt edit only if separately authorized. | All rows remain reachable; responsive/keyboard behavior is documented. Do not assume the README grid is editable: Forms XML marks COURSE and SECTION blocks read-only. | Defined; exact grid UX and edit scope need owner confirmation. |
| F2-REL-04 | Master delete with children (`F2-TR-10`) | In an isolated fixture, compare a master with and without SECTION rows; execute delete only after write authorization. | Legacy source blocks deletion when matching details exist and shows “Cannot delete master record when matching detail records exist.” APEX must not delete a parent with children; exact web behavior awaits approval. | Defined from Forms source; not run. COURSE is read-only in Forms XML and APEX. |
| F2-ZIP-01 | INSTRUCTOR ZIP lookup (`F2-TR-04`) | With a synthetic instructor and ZIP fixture, open the lookup and select a ZIP. | The selected ZIP returns to `INSTRUCTOR.ZIP`; CITY/STATE are not assumed to populate because no return mapping is present in the XML. | PASS: selected `99999 - TESTVILLE, ZZ`, created instructor 115, and read back `ZIP=99999` from the base table. The instructor and ZIP fixtures were then removed. |
| F2-DML-01 | INSTRUCTOR create/update/delete (`F2-TR-02`, `F2-TR-03`) | Create a marked instructor with the synthetic ZIP; update its phone; verify audit; delete the same row. | Generated ID and audit values persist; ZIP round-trips; update preserves creation audit and advances modification audit; delete leaves no fixture row. | PASS: created instructor 115 with ZIP 99999, updated phone from `0000000000` to `0000000001`, verified audit by SQL, and deleted the row through page 8. |
| F2-ZIP-02 | ZIP lookup cancel/no result/stale value | Cancel the lookup, search for a ZIP with no match, and verify a stale ZIP under an isolated approved fixture. | Cancel preserves the prior item value; no-result and stale-value feedback are explicit; no invalid value persists. | NOT RUN: the APEX control is an inline select list; cancel/no-result/stale-value behavior remains unverified. |
| F2-NAV-01 | Instructor to Course and Student windows (`F2-TR-05`, `F2-TR-06`) | Invoke each navigation action as `QAFE_FORMS_BUILDER`. | Course and Student journeys open within the approved local scope; return navigation is predictable. | PASS for web navigation: Instructors, Students, Course Overview, and nested Section Overview opened in the authenticated session. This does not establish Forms button equivalence. |
| F2-NAV-02 | Return from Course/Student (`F2-TR-07`, `F2-TR-08`) | Return from each secondary window/page; test unsaved state only with approved isolated writes. | Return path and focus are accessible; unsaved changes are preserved or canceled only according to an approved rule. | PARTIAL: menu navigation between pages worked; return focus and unsaved-change behavior were not tested. |
| F2-REL-05 | Concurrent detail changes | With isolated authorized fixtures, update a SECTION from two sessions and submit the stale version. | Lost-update behavior is detected or resolved by an approved rule; no silent overwrite occurs. | Defined; concurrency policy and fixture are not approved. |

## Source Limits

- INSTRUCTOR and STUDENT Forms blocks have DML flags enabled; COURSE and SECTION are read-only in the export. Flags do not prove persistence.
- `V_QAFE_FORM2_INSTRUCTOR_TRG` and `V_QAFE_FORM2_STUDENT_TRG` have no-op UPDATE/DELETE branches (`WHERE 1 = 0`). The owner approved correcting the APEX target with guarded base-table DML; the legacy triggers remain unchanged.
- `ZIP_LOV` uses `select zip, city, state from zipcode`; only ZIP maps back to `INSTRUCTOR.ZIP` in the export.
- After runtime acceptance cleanup, the clean PDB contains no synthetic INSTRUCTOR, STUDENT, SECTION, or ZIPCODE rows. COURSE remains the three approved preview rows. Do not copy historical or production rows.
- The owner approved local CRUD for INSTRUCTOR/STUDENT. Do not use `V_QAFE_FORM2_INSTRUCTOR_TRG` or `V_QAFE_FORM2_STUDENT_TRG` for target DML because their UPDATE/DELETE branches are no-ops; use guarded base-table DML and retain the default-deny boundary outside the local Builder.