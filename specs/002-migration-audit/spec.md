# Feature Specification: Migration Audit Assistant

**Feature Branch**: `002-migration-audit`

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "Add extensible, read-only audit tools for the Oracle Forms to APEX migration, with traceable evidence and optional agent orchestration."

## User Scenarios & Testing

### User Story 1 - Find source evidence (Priority: P1)

As a migration reviewer, I want to search the project's approved text sources and see the exact file and line for each match so that migration decisions can be checked against source evidence.

**Why this priority**: Evidence retrieval is the foundation for every subsequent review and works without an AI service.

**Independent Test**: Search for a known trigger or traceability identifier and verify each result includes a repository-relative path and line number.

**Acceptance Scenarios**:

1. **Given** the repository sources, **When** a reviewer searches for a known Forms trigger, **Then** matching excerpts are returned with file paths and line numbers.
2. **Given** a search request, **When** a query is empty or no source matches, **Then** the tool returns a bounded, explicit result and does not read files outside its approved source directories.
3. **Given** one of the three known Forms modules, **When** a reviewer requests an inspection, **Then** the tool reports structured block, item, and trigger properties from that module's XML export.

### User Story 2 - Review traceability and open decisions (Priority: P1)

As a migration reviewer, I want to retrieve a traceability entry and identify missing acceptance-test documents or unresolved risks so that gaps are visible before implementation.

**Why this priority**: The project already has a traceability matrix and a risk register, and their gaps should remain explicit rather than being guessed by an agent.

**Independent Test**: Inspect `F3-TR-03`, audit all test-record links, and confirm unresolved findings include their source identifiers and status.

**Acceptance Scenarios**:

1. **Given** a source identifier in the traceability matrix, **When** the reviewer requests it, **Then** the matching row and its proof status are returned.
2. **Given** the traceability matrix, **When** the reviewer runs the coverage audit, **Then** existing and missing acceptance-test paths are reported without modifying project files.
3. **Given** open or blocking project risks, **When** the reviewer requests open items, **Then** the risk identifiers and unresolved proof entries are listed for human review.

### User Story 3 - Ask an agent to use the audit tools (Priority: P2)

As a reviewer, I want an Agent Framework agent to call the same read-only audit tools so that I can ask questions in natural language while retaining the same evidence boundary.

**Why this priority**: Natural-language orchestration is useful, but source-grounded tools must exist and be independently testable first.

**Independent Test**: Construct the agent with an injected chat client and verify only the documented read-only tools are registered; no model call is required for this check.

**Acceptance Scenarios**:

1. **Given** an explicitly supplied chat client, **When** the audit agent is constructed, **Then** it receives only the bounded search, traceability, coverage, and open-item tools.
2. **Given** no provider configuration, **When** the deterministic audit CLI is used, **Then** all local audit tools remain usable without reading `.env`, contacting a model, or connecting to Oracle.

### Edge Cases

- A referenced source or acceptance-test file may be missing; the audit reports the missing path rather than silently dropping the row.
- A source identifier may be malformed or absent; it must not be interpreted as a filesystem path.
- A line may contain long or non-UTF-8 content; search output is bounded and decoding errors do not expose unrelated file contents.
- No unresolved items or no search matches is a valid result and must be distinguishable from a tool failure.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST restrict source search to approved, repository-local text files and MUST exclude environment files, binary artifacts, and files outside the approved documentation, specification, test, and script directories.
- **FR-002**: Every search match MUST include a repository-relative path, a one-based line number, and a bounded excerpt.
- **FR-003**: The system MUST retrieve a traceability row by its source identifier and preserve the recorded proof status.
- **FR-004**: The system MUST report whether each acceptance-test path referenced by the traceability matrix exists.
- **FR-005**: The system MUST expose open and blocking risks and traceability entries whose proof remains unknown, unverified, or untested.
- **FR-006**: The system MUST NOT modify migration sources, connect to Oracle, execute shell commands, or make approval decisions.
- **FR-007**: Agent orchestration MUST receive its model client from the caller and MUST expose only the same read-only audit tools.
- **FR-008**: The deterministic audit tools MUST work without provider credentials, network access, or loading `.env`.
- **FR-009**: Tool outputs MUST preserve source identifiers and status as recorded; the system MUST NOT infer owner approval or resolve ambiguous business rules.
- **FR-010**: The system MUST inspect only the three allowlisted Forms XML exports and MUST reject unknown module names rather than accepting arbitrary paths.

### Key Entities

- **Evidence Match**: A source excerpt identified by a repository-relative path and one-based line number.
- **Traceability Entry**: A source identifier, recorded behavior, acceptance-test reference, and proof status from the migration matrix.
- **Review Item**: An open risk or traceability entry requiring confirmation, testing, or owner decision.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Every returned search match identifies the exact repository-relative path and one-based line containing the match.
- **SC-002**: A reviewer can retrieve a known traceability entry and its proof status using its source identifier.
- **SC-003**: The coverage audit reports all acceptance-test references as present or missing, with no reference silently omitted.
- **SC-004**: The audit completes using only local project files and leaves the repository and database unchanged.
- **SC-005**: Automated tests verify the source boundary, evidence citations, traceability lookup, missing-test reporting, and agent tool registration without contacting a model or database.

## Assumptions

- The repository's existing `docs/traceability-matrix.md` and `docs/migration-risks.md` are the initial sources of truth for traceability and unresolved decisions.
- The first increment is a local reviewer tool, not a production service or replacement for Spec Kit.
- Agent Framework orchestration is optional; deterministic tools remain usable independently.
- Additional source directories, checks, tools, providers, and workflows can be added as separately tested increments.