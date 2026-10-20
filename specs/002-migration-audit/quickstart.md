# Quickstart: Migration Audit Assistant

Run from the repository root with Python 3.13 or later.

## Deterministic local tools

```powershell
python -m tools.migration_audit audit
python -m tools.migration_audit trace F3-TR-03
python -m tools.migration_audit search "WHEN-VALIDATE-ITEM"
python -m tools.migration_audit inspect-form QAFE_FORM1
python -m tools.migration_audit open-items
python -m unittest discover -s tests/tools -v
```

The CLI reads only repository-local Markdown, XML, and SQL under `docs/`, `specs/`, `tests/`, and `script/`. It does not read `.env`, access Oracle, call a model, or write files. Search output contains relative paths and one-based line numbers. Missing test references and unresolved proof are findings for human review, not automatic approvals.

## Optional Agent Framework adapter

Install the Microsoft Agent Framework Python package in the chosen environment with `python -m pip install agent-framework`. Construct a provider client according to the provider and credential policy selected by the project, then pass that client to `create_audit_agent(client, root)`. The adapter does not load `.env` or create a client. No provider integration test is run until a provider and credentials are explicitly configured.