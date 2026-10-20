# Tasks: Migration Audit Assistant

**Input**: Design documents from `specs/002-migration-audit/`

**Prerequisites**: `plan.md`, `spec.md`

## Phase 1: Setup

**Purpose**: Add the isolated local toolkit structure.

- [x] T001 Create the importable package in `tools/migration_audit/__init__.py`
- [x] T002 Add the local usage guide in `tools/migration_audit/README.md`

## Phase 2: Foundational

**Purpose**: Implement bounded source discovery and structured outputs.

- [x] T003 Implement approved source enumeration and Markdown table parsing in `tools/migration_audit/toolkit.py`
- [x] T004 Add isolated tests for source boundaries and table parsing in `tests/tools/test_migration_audit.py`

## Phase 3: User Story 1 - Find source evidence (Priority: P1)

**Goal**: Return bounded search excerpts with repository-relative paths and line numbers.

**Independent Test**: Search a known source string and verify its cited path and line; verify an environment file is not searched.

- [x] T005 [US1] Implement evidence search with bounded results in `tools/migration_audit/toolkit.py`
- [x] T006 [US1] Test cited search results and excluded files in `tests/tools/test_migration_audit.py`
- [x] T014 [US1] Implement allowlisted structured Forms XML inspection in `tools/migration_audit/toolkit.py`
- [x] T015 [US1] Expose `inspect-form` in `tools/migration_audit/__main__.py` and `tools/migration_audit/agent.py`
- [x] T016 [US1] Test the QAFE_FORM1 XML contract and unknown-module rejection in `tests/tools/test_migration_audit.py`

## Phase 4: User Story 2 - Review traceability and open decisions (Priority: P1)

**Goal**: Look up source IDs and report acceptance-test gaps and unresolved items.

**Independent Test**: Retrieve `F3-TR-03` and verify proof status; report whether all linked test paths exist.

- [x] T007 [US2] Implement traceability lookup, coverage audit, and review queue in `tools/migration_audit/toolkit.py`
- [x] T008 [US2] Test known entries, missing acceptance tests, and open risks in `tests/tools/test_migration_audit.py`
- [x] T009 [US2] Add the local `audit`, `search`, `trace`, and `open-items` commands in `tools/migration_audit/__main__.py`

## Phase 5: User Story 3 - Ask an agent to use the audit tools (Priority: P2)

**Goal**: Make the same read-only tools available to an Agent Framework agent with an injected client.

**Independent Test**: Use a fake framework agent in a unit test and verify only the bounded toolkit methods are registered.

- [x] T010 [US3] Add the lazy Agent Framework adapter in `tools/migration_audit/agent.py`
- [x] T011 [US3] Test agent tool registration without a provider call in `tests/tools/test_migration_audit.py`

## Phase 6: Polish

**Purpose**: Document verification commands and validate the MVP.

- [x] T012 Update the feature quickstart in `specs/002-migration-audit/quickstart.md`
- [x] T013 Run the focused unit suite and CLI audit from the repository root

## Dependencies & Execution Order

- Setup precedes the foundational toolkit and tests.
- User Story 1 establishes evidence search; User Story 2 extends the same source reader and is next.
- User Story 3 depends on the bounded methods from User Stories 1 and 2 but remains optional at runtime.
- Run the unit suite after each story; validate the CLI after User Story 2 and the optional adapter after User Story 3.

## Implementation Strategy

Deliver the local deterministic tools first. Keep the agent adapter thin and optional so missing model configuration never blocks local audits. Stop before adding multi-agent analysis, write access, or database integration.