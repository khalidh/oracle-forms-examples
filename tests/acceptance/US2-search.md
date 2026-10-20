# US2 Search and Consultation Acceptance Record

**Feature**: `001-forms-apex-migration`  
**Status**: `F1-SRC-01` and the approved local `F1-DEMO-01` preview passed. The broader US2 scenarios and production authorization remain untested/unapproved.  
**Data boundary**: Sanitized, isolated fixtures only. Never copy production data or run write tests against the legacy schema.

## Source-backed Journeys

| Journey | Confirmed Forms evidence | Candidate read scope |
|---|---|---|
| Courses | `QAFE_FORM1` opens and queries COURSE; `QAFE_FORM2` has a COURSE query source and a button that queries/shows it; `QAFE_FORM3` opens and queries COURSE. | Course records from the example `COURSE` source. |
| Instructors | `QAFE_FORM2` opens and queries INSTRUCTOR. | Instructor records from the example `INSTRUCTOR` source. |
| Students | `QAFE_FORM2` has a STUDENT query source and a button that queries/shows it. | Student records from the example `STUDENT` source. |
| Sections | `QAFE_FORM2` COURSE_SECTION relates COURSE to SECTION by `SECTION.COURSE_NO = COURSE.COURSE_NO`; `QAFE_FORM3` queries SECTION on block entry. | Sections in the approved course context; exact standalone search behavior is unconfirmed. |

These are source observations, not approval of which columns a user may see or search. Form 3's derived section/student counts are separately recorded in the traceability matrix.

## QAFE_FORM1 Source-Contract Test

| ID | Check | Expected | Observed | Status |
|---|---|---|---|---|
| F1-SRC-01 | Inspect the `QAFE_FORM1` Forms2XML export for COURSE query configuration. | Query source, query-enabled items, explicit filters/order, startup query, and unresolved item binding are reported from the XML. | COURSE source is `course`; block and all eight items allow query; block WHERE and ORDER BY are empty; startup calls `execute_query()`; `COURSE_NO.ColumnName` is empty. | PASS (source evidence only) |

Re-run with `python -m unittest tests.tools.test_migration_audit.AuditToolkitTests.test_form_inspection_returns_structured_qafe_form1_query_facts -v`. This verifies the exported XML contract, not Forms runtime or APEX behavior.

## Local Demo Decision (2026-10-19; clean-destination extension 2026-10-20)

- Actor: any authenticated user of the local demo workspace only.
- Data: local example COURSE data; first assertions cover sample course numbers 454, 455, and 456 from `script/student-db-script.sql`.
- Visible columns: `COURSE_NO`, `DESCRIPTION`, and `COST` only.
- List behavior: unfiltered COURSE list, sorted by `COURSE_NO` ascending, 10 rows per page.
- Writes: create, update, and delete remain denied.
- Initial boundary: local `ORACLE_FORMS_EXAMPLES` PDB and `127.0.0.1` only. On 2026-10-20 the owner selected the side-by-side `QAFE_CLEAN` PDB/workspace for the first migration slice; the same three-column, three-row, read-only preview is loopback-only. These choices are not claims about Forms behavior or production authorization.

## Acceptance Scenarios

| ID | Scenario | Setup and action | Expected result | Status |
|---|---|---|---|---|
| US2-AC-01 | Matching query | Load sanitized fixture records with known expected IDs. As an authorized read actor, submit a match using a criterion approved and traced in T017. | The result contains exactly the expected in-scope records, once each; related sections use the confirmed COURSE_SECTION join. The query causes no database mutation. | Defined; blocked on approved criteria and read role. |
| US2-AC-02 | Empty result | Use a valid, source-approved criterion/value with no matching fixture record. | No records are returned; an explicit empty state is shown; no unrelated record is exposed and no data is changed. | Defined; blocked on approved criteria and UI design. |
| US2-AC-03 | Multiple results | Use a source-approved criterion/value matching at least two fixture records. | Every expected record is returned once, with no out-of-scope records. Result count is consistent with the fixture. | Defined; blocked on approved criteria and fixture. |
| US2-AC-04 | Pagination | Seed more matching fixture rows than the approved page capacity, then traverse forward/back and return to the query. | Each expected row is reachable exactly once; no omissions or duplicates; the approved ordering and query are preserved across pages. Page capacity and ordering are not specified by Forms and need approval in T017. | Defined; blocked on page design and fixture. |
| US2-AC-05 | Default-deny authorization | Attempt each read journey as anonymous and as an identity with no approved grant; also request a page/report endpoint directly rather than using navigation. | Access is denied server-side for every business-data journey. Hiding a link or control alone does not count as authorization. | Defined; current rule from `docs/security-matrix.md`; execute after workspace/auth setup. |
| US2-AC-06 | Approved read scope | After the owner approves named roles and row/column scope, run the matching, empty, and multiple-result scenarios as each permitted role and as a role without that grant. | Permitted reads show only the approved scope; unapproved roles remain denied. Changing URL, request parameters, or session state cannot broaden access. | Blocked on owner-approved authorization matrix. |
| US2-AC-07 | Read-only behavior | Run all search, result navigation, and related-section scenarios; attempt any write path available from the page or direct request. | Consultation does not insert, update, or delete records. Business writes remain denied until separately approved; no search page infers authorization from Forms DML flags. | Defined; execute with isolated fixture after implementation. |

| F1-DEMO-01 | Local Form 1 read-only list | Sign in to `QAFE_FORMS_CLEAN` as `QAFE_FORMS_BUILDER`, open application 100 page 4, remove the initial session filter, and reload after saving default report settings. | Only `COURSE_NO`, `DESCRIPTION`, and `COST` are visible; rows 454/455/456 show English Grammar/30, Mathematics/20, and Dutch Grammar/40 in ascending course-number order. The shared default rows-per-page setting is 10. The page is an Interactive Report with no form or DML process. | PASS, 2026-10-20: all three rows and columns observed; the 10-row default remained selected after reload. No write action was invoked. |

## Open Decisions / Test Data

- `docs/migration-mapping.md` records the Form 1 source facts: no explicit block filter or ordering, eight projected columns, query-enabled items, and the unresolved COURSE_NO binding. The approved local demo settings are separate from Forms behavior.
- Forms desktop overflow does not establish APEX pagination semantics; the 10-row page and ascending order are local demo choices only.
- `docs/security-matrix.md` retains default deny for general and production use; the authenticated local demo scope is a narrow exception and does not approve other data or roles.
- `QAFE_FORMS_CLEAN` application 100 contains the approved local Form 1 slice only. Do not infer that US2-AC-01 through US2-AC-07 or the other Forms journeys passed from `F1-DEMO-01`.
- Create only isolated, sanitized fixtures under the policy in `tests/fixtures/README.md`. Record identifiers, relationships, and reset procedure before populating them. Use at least zero, one, and multiple matching rows, plus a result set larger than the approved page capacity.
- Do not use `V_EX01_01_STUDENT` as a source; its `STUDENT_TEST` dependency is absent from the supplied DDL. Do not validate search by changing legacy data.

## Traceability

- `F1-TR-01`, `F2-TR-01`, `F2-TR-05`, `F2-TR-06`, `F2-TR-09`, `F3-TR-01`, `F3-TR-02`, `F3-TR-05`, and `F3-TR-07` in `docs/traceability-matrix.md`.
- Query sources and block DML flags: `docs/forms-inventory.md` and `docs/data-model.md`.
- Access gate: `docs/security-matrix.md`.
