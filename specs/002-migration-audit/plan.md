# Implementation Plan: Migration Audit Assistant

**Branch**: `002-migration-audit` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-migration-audit/spec.md`

## Summary

Add a local, read-only audit toolkit for searching evidence, inspecting traceability, checking acceptance-test references, and surfacing unresolved items. Keep the core deterministic and usable without credentials; expose those same bounded functions as optional Microsoft Agent Framework function tools through a caller-injected chat client.

## Technical Context

**Language/Version**: Python 3.13 (available in the workspace)

**Primary Dependencies**: Python standard library for audit and CLI; optional `agent-framework` package for the agent adapter

**Storage**: Existing repository files only; no database or generated persistent state

**Testing**: `unittest` from the Python standard library

**Target Platform**: Local Windows development workspace; platform-neutral Python source

**Project Type**: Local read-only CLI and importable tool library

**Performance Goals**: Keep each tool invocation bounded by a maximum search result count; target repository-sized documentation, not bulk database scans

**Constraints**: No `.env` loading, model call, Oracle connection, shell tool, writes to source files, or inference of owner decisions. Framework/provider dependencies remain optional.

**Scale/Scope**: Initial approved roots are `docs/`, `specs/`, `tests/`, and `script/`; text extensions are Markdown, XML, and SQL. Extend via explicit code changes and tests.

## Constitution Check

The repository constitution is still the uncustomized Spec Kit template, so it defines no ratified project principles. This plan follows the existing project guardrails in `docs/resume.md`, `docs/migration-risks.md`, and `tests/fixtures/README.md`: default deny for business operations, no secrets in source context, no production data, and no database writes. **Gate: PASS** for this read-only local scope.

## Project Structure

### Documentation

```text
specs/002-migration-audit/
├── spec.md
├── plan.md
├── tasks.md
├── quickstart.md
└── checklists/
    └── requirements.md
```

### Source Code

```text
tools/migration_audit/
├── __init__.py
├── __main__.py
├── toolkit.py
└── agent.py

tests/tools/
└── test_migration_audit.py
```

**Structure Decision**: Place this local tool under `tools/migration_audit/` to keep it separate from APEX application code and the paused migration feature. Pure functions and `AuditToolkit` own deterministic operations; `agent.py` is a thin, optional Agent Framework adapter. Future analyzers and workflows can be added as separate modules without changing the existing Spec Kit feature pointer.

## Design Decisions

- Search is restricted to explicit project directories and text suffixes; tool arguments cannot select arbitrary filesystem paths.
- Tool outputs are JSON strings with source paths and line numbers so they are inspectable both from the CLI and through function-tool calls.
- The adapter accepts a preconfigured client. Provider choice, credentials, and deployment configuration are not assumed or read from `.env`.
- Multi-agent review, generated reports written to disk, database access, and automatic source edits are deferred until there is an approved use case and tests.

## Complexity Tracking

No constitution violations or additional services are introduced.