# Tasks: Migration des formulaires Oracle Forms vers Oracle APEX

**Input**: Design documents from `specs/001-forms-apex-migration/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`; no external API contracts were identified.

**Tests**: Acceptance scenarios are explicitly required by `spec.md`; each story includes a test-record task.

**Organization**: Tasks are grouped by user story. Legacy Forms files, Oracle schema, and data remain read-only during discovery. Business operations stay denied by default until the authorization matrix is approved.

## Path Conventions

- Legacy inputs: repository-root `QAFE_FORM*.fmb` and `script/student-db-script.sql`
- Derived exports: `docs/forms-exports/`
- Migration documentation: `docs/`
- APEX application export after implementation approval: `apex/QAFE_MIGRATION.sql`
- Acceptance records: `tests/acceptance/`

## Phase 1: Setup

**Purpose**: Establish safe, source-controlled locations and repeatable evidence conventions.

- [x] T001 [P] Create the non-overwrite Forms XML export procedure and evidence/hash fields in `docs/forms-exports/README.md`
- [x] T002 [P] Create the acceptance-record template with preconditions, action, expected UI/result, persisted state, source ID, and proof status in `tests/acceptance/README.md`
- [x] T003 [P] Document the APEX export artifact location, approval boundary, and no-secrets rule in `apex/README.md`

## Phase 2: Foundational

**Purpose**: Confirm the target environment and test-data boundaries before any APEX implementation.

- [x] T004 Record observed Oracle Database/APEX versions, ORDS/XML DB status, patch level, and pending owner approvals in `docs/apex-environment.md`
- [x] T005 Provision or identify an owner-approved non-production APEX 24.2 environment with ORDS 23.3 or later, and record its base URL and versions in `docs/apex-environment.md` (depends on T004)
- [x] T006 Define an isolated, sanitized STUDENT test-fixture policy and prohibit production-data copies in `tests/fixtures/README.md`
- [x] T007 Record the interim default-deny rule and the pending authorization-matrix approval in `docs/security-matrix.md`

**Checkpoint**: No story may modify or expose business operations until the test environment, source evidence policy, and access gate are documented.

## Phase 3: User Story 1 - Establish a Verifiable Migration Baseline (Priority: P1)

**Goal**: Produce a provenance-backed inventory and make every unknown explicit before designing migrated behavior.

**Independent Test**: A reviewer can trace every legacy claim to README, SQL, or Forms XML; every unexported component is marked unverified and none is invented.

### Tests for User Story 1

- [x] T008 [US1] Record an inventory acceptance review proving every listed component has a source reference or an explicit unknown status in `tests/acceptance/US1-inventory.md`

### Implementation for User Story 1

- [x] T009 [P] [US1] Export `QAFE_FORM1.fmb` with Forms2XML using stable property IDs and full property dump, then move `QAFE_FORM1_fmb.xml` into `docs/forms-exports/` without overwriting; preserve the source FMB
- [x] T010 [P] [US1] Export `QAFE_FORM2.fmb` with Forms2XML using stable property IDs and full property dump, then move `QAFE_FORM2_fmb.xml` into `docs/forms-exports/` without overwriting; preserve the source FMB
- [x] T011 [P] [US1] Export `QAFE_FORM3.fmb` with Forms2XML using stable property IDs and full property dump, then move `QAFE_FORM3_fmb.xml` into `docs/forms-exports/` without overwriting; preserve the source FMB
- [x] T012 [US1] Inventory exported modules, README claims, SQL objects, missing libraries, menus, forms, and unresolved dependencies in `docs/forms-inventory.md`
- [x] T013 [US1] Map each exported Forms trigger/program unit to its event, condition, side effect, message, SQL object, and proof status in `docs/trigger-analysis.md`
- [x] T014 [US1] Reconcile all 11 SQL tables, 7 views, keys, constraints, sequences, types, packages, and exported block bindings in `docs/data-model.md`
- [x] T015 [US1] Update the role inventory from exported Forms evidence while retaining default deny and listing unresolved permissions in `docs/security-matrix.md`

**Checkpoint**: User Story 1 is complete when all three exports are recorded, the six analysis documents are evidence-backed or explicitly incomplete, and no unverified component is presented as fact.

## Phase 4: User Story 2 - Search and Consult Business Data (Priority: P1)

**Goal**: Let authorized users find and view confirmed course, student, instructor, and related data journeys.

**Independent Test**: On the approved test environment, matching, empty, and multi-row queries return only the expected records, preserve navigation, and do not change persisted data.

### Tests for User Story 2

- [x] T016 [US2] Record matching, empty-result, multi-result, pagination, and authorization scenarios against confirmed Forms sources in `tests/acceptance/US2-search.md`

### Implementation for User Story 2

- [x] T017 [US2] Map confirmed Forms query criteria, result fields, ordering, empty states, and navigation to target journeys in `docs/migration-mapping.md`
- [ ] T018 [US2] Build the approved APEX search and consultation pages and export the application to `apex/QAFE_MIGRATION.sql`; keep business operations disabled until the authorization gate passes

**Checkpoint**: User Story 2 passes when the acceptance record shows all query scenarios and read-only access is restricted to approved roles.

## Phase 5: User Story 3 - Create and Maintain Data (Priority: P1)

**Goal**: Preserve the README-declared CRUD behavior while resolving the SQL trigger no-op discrepancy before implementation.

**Independent Test**: In the isolated test schema, each approved create/update/delete produces the expected persistent state or a truthful, non-persisting rejection.

### Tests for User Story 3

- [ ] T019 [US3] Record create/update/delete cases, generated keys, audit values, constraint failures, and persisted-state checks in `tests/acceptance/US3-crud.md`

### Implementation for User Story 3

- [ ] T020 [US3] Obtain owner sign-off for treating `WHERE 1 = 0` UPDATE/DELETE branches as defects and record the decision and source references in `docs/migration-mapping.md`
- [ ] T021 [US3] Implement the approved CRUD journeys with verified persistence and transaction outcomes in `apex/QAFE_MIGRATION.sql` only after T020 is approved

**Checkpoint**: Do not enable a CRUD action until its authorization is approved and its acceptance case verifies the resulting database state.

## Phase 6: User Story 4 - Preserve Validations and Error Handling (Priority: P1)

**Goal**: Preserve confirmed business validations and provide actionable failure feedback without partial writes.

**Independent Test**: Valid and invalid values, including null FIRST_NAME and present/missing ZIP cases, produce the approved messages and expected persisted state.

### Tests for User Story 4

- [ ] T022 [US4] Record positive, negative, boundary, and no-partial-write cases for each confirmed validation in `tests/acceptance/US4-validation.md`

### Implementation for User Story 4

- [ ] T023 [US4] Extend the trigger analysis with Forms timing, error handling, and exact validation source mappings from exports in `docs/trigger-analysis.md`
- [ ] T024 [US4] Implement approved server-side validations and user-facing error outcomes in `apex/QAFE_MIGRATION.sql` without weakening database constraints

**Checkpoint**: No validation is considered preserved until its positive and negative cases pass against the isolated target.

## Phase 7: User Story 5 - Navigate Grids and Related Data (Priority: P2)

**Goal**: Preserve confirmed master-detail, grid, and ZIP lookup behavior in a web-appropriate journey.

**Independent Test**: Selecting a master record, editing detail rows, choosing or cancelling a ZIP lookup, and handling missing related data produce the approved UI and database outcomes.

### Tests for User Story 5

- [ ] T025 [US5] Record master-detail, grid, ZIP lookup, cancel, missing-parent, and concurrent-edit cases in `tests/acceptance/US5-related-data.md`

### Implementation for User Story 5

- [ ] T026 [US5] Specify confirmed master-detail, grid, and LOV outcomes and desktop-to-web differences in `docs/migration-mapping.md`
- [ ] T027 [US5] Implement only the confirmed related-data journeys and selected APEX components in `apex/QAFE_MIGRATION.sql`

**Checkpoint**: User Story 5 passes when relationship integrity, selection/cancel flows, and concurrent-edit outcomes match approved tests.

## Phase 8: User Story 6 - Accept Incremental Migration Slices (Priority: P2)

**Goal**: Deliver bounded migration increments with traceability and explicit acceptance before retiring any Forms path.

**Independent Test**: Every accepted slice has source-to-test traceability, signed acceptance, known residual risks, and a rollback path.

### Tests for User Story 6

- [ ] T028 [US6] Record slice-level source coverage, test results, unresolved findings, and owner acceptance in `tests/acceptance/US6-slice-signoff.md`

### Implementation for User Story 6

- [ ] T029 [US6] Build the source-to-rule-to-requirement-to-APEX-behavior-to-test matrix with proof statuses in `docs/traceability-matrix.md`
- [ ] T030 [US6] Define incremental scope, dependencies, cutover gates, and Forms coexistence risks in `docs/migration-risks.md`

**Checkpoint**: A slice is not accepted and Forms is not decommissioned while source coverage, security approval, or required regression tests remain incomplete.

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Close operational, accessibility, performance, audit, and recovery requirements across all stories.

- [ ] T031 [P] Define and record browser, keyboard, screen-reader, and responsive acceptance scenarios in `tests/acceptance/platform-quality.md`
- [ ] T032 [P] Measure representative production-like data volumes and record approved response-time targets in `docs/apex-environment.md`
- [ ] T033 Document backup, rollback, audit, logging, and recovery procedures for the approved deployment in `docs/migration-risks.md`
- [ ] T034 Run the approved end-to-end scenarios and update prerequisites, commands, and expected outcomes in `specs/001-forms-apex-migration/quickstart.md`

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; export, test-record, and APEX artifact conventions can be prepared in parallel.
- **Foundational (Phase 2)**: Requires Setup; target environment and access/test-data gates block all APEX implementation.
- **US1 (Phase 3)**: Requires Setup and owner-approved Forms2XML export; independent of ORDS provisioning, but required before confirming later stories.
- **US2 (Phase 4)**: Requires US1 confirmed query journeys and the approved APEX/ORDS test environment.
- **US3 (Phase 5)**: Requires US1 DML evidence, approved CRUD discrepancy decision, and US2 APEX artifact baseline.
- **US4 (Phase 6)**: Requires US1 trigger exports and the shared APEX artifact from earlier stories.
- **US5 (Phase 7)**: Requires US1 relationship/LOV evidence and the shared APEX artifact; sequence after US4 to avoid export-file conflicts.
- **US6 (Phase 8)**: Requires all selected user stories and their passing acceptance evidence.
- **Polish (Phase 9)**: Requires the candidate release slice and representative test environment.

### User Story Dependencies

- **US1 (P1)**: Starts after Setup; exports and inventory are prerequisites for all behavior stories.
- **US2 (P1)**: Starts after Foundational and US1; first user-visible APEX slice.
- **US3 (P1)**: Starts after US2; requires owner sign-off of the CRUD discrepancy before DML work.
- **US4 (P1)**: Starts after US1 and US3; only rules confirmed by export are implemented.
- **US5 (P2)**: Starts after US1; implement after the shared APEX export has US2-US4 changes.
- **US6 (P2)**: Starts after all selected slices and acceptance records are complete.

### Parallel Opportunities

- Setup tasks T001-T003 touch separate files and can run in parallel.
- Forms2XML exports T008-T010 touch separate output files and can run in parallel after export approval.
- Foundational environment, sanitized-fixture policy, and interim security policy can be documented in parallel after source scope is agreed.
- Story implementation tasks T017, T020, T023, and T026 all update `apex/QAFE_MIGRATION.sql`; do not run them in parallel. Execute in story order and re-export/retest after each change.
- Traceability T028 can be drafted from completed story records, but slice sign-off T030 waits for the final matrix and risk review.

## Parallel Example: User Story 1

```text
Task: T009 Export QAFE_FORM1 to docs/forms-exports/QAFE_FORM1_fmb.xml
Task: T010 Export QAFE_FORM2 to docs/forms-exports/QAFE_FORM2_fmb.xml
Task: T011 Export QAFE_FORM3 to docs/forms-exports/QAFE_FORM3_fmb.xml
```

## Implementation Strategy

### MVP First

1. Complete Setup and Foundational gates without touching the source schema.
2. Complete US1 and review all three exports, inventory, and proof gaps.
3. Stop for owner validation of the CRUD discrepancy, roles, and environment gates.
4. Implement US2 read-only consultation as the first candidate APEX slice, then validate before enabling any business writes.

### Incremental Delivery

1. Finish the source inventory and baseline.
2. Deliver and test read-only consultation journeys.
3. Resolve DML discrepancies and then enable approved CRUD.
4. Add validations, related-data grids/LOVs, and slice sign-off in sequence.
5. Retire a Forms journey only after traceability, acceptance, security, and rollback gates pass.