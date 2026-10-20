"""Optional Microsoft Agent Framework adapter for the read-only audit tools."""

from pathlib import Path
from typing import Any

from .toolkit import AuditToolkit


def create_audit_agent(client: Any, root: Path) -> Any:
    """Create an agent using an explicitly configured client and bounded local tools."""
    try:
        from agent_framework import Agent
    except ImportError as error:
        raise RuntimeError(
            "Install the optional Microsoft Agent Framework package with "
            "'python -m pip install agent-framework'."
        ) from error

    toolkit = AuditToolkit(root)
    return Agent(
        client=client,
        name="MigrationAuditAgent",
        instructions=(
            "Answer in French. Use only the supplied read-only audit tools. "
            "Ground every project claim in returned paths, line numbers, source IDs, "
            "and recorded proof statuses. Do not infer owner approval, resolve ambiguous "
            "business rules, access files outside the tools, or propose unverified behavior as fact."
        ),
        tools=[
            toolkit.search_evidence,
            toolkit.inspect_form,
            toolkit.get_traceability,
            toolkit.audit_traceability,
            toolkit.list_open_items,
        ],
    )