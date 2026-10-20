# Migration Audit Tools

This package provides local, read-only tools for reviewing migration evidence. The deterministic CLI and toolkit use only Markdown, XML, and SQL files under `docs/`, `specs/`, `tests/`, and `script/`. They do not read `.env`, access Oracle, run shell commands, call a model, or change files.

Run these commands from the repository root:

```powershell
python -m tools.migration_audit audit
python -m tools.migration_audit trace F3-TR-03
python -m tools.migration_audit search "WHEN-VALIDATE-ITEM"
python -m tools.migration_audit inspect-form QAFE_FORM1
python -m tools.migration_audit open-items
python -m unittest discover -s tests/tools -v
```

The five functions on `AuditToolkit` are also suitable as Microsoft Agent Framework function tools. `inspect_form` parses only the three known Forms XML exports and returns structured block, item, and trigger facts. The optional adapter in `agent.py` accepts a provider client created by the caller; it never loads credentials or `.env` itself:

```python
from pathlib import Path

from tools.migration_audit.agent import create_audit_agent

agent = create_audit_agent(configured_client, Path.cwd())
```

Install `agent-framework` into the selected Python environment only when enabling that adapter. Choose and configure the provider separately. The local CLI and tests do not require the package or a model endpoint.