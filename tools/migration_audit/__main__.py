"""Command-line entry point for local migration audits."""

import argparse
from pathlib import Path

from .toolkit import AuditToolkit


def main() -> None:
    parser = argparse.ArgumentParser(description="Read-only Oracle Forms migration evidence audit")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="repository root (defaults to this project's root)",
    )
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("audit", help="check acceptance-test links in the traceability matrix")
    search = commands.add_parser("search", help="search approved local text sources")
    search.add_argument("query")
    search.add_argument("--limit", type=int, default=10)
    trace = commands.add_parser("trace", help="retrieve a traceability row by source identifier")
    trace.add_argument("source_id")
    inspect_form = commands.add_parser("inspect-form", help="inspect a known Forms XML export")
    inspect_form.add_argument("form_name", choices=("QAFE_FORM1", "QAFE_FORM2", "QAFE_FORM3"))
    commands.add_parser("open-items", help="list recorded risks and unverified traceability")
    args = parser.parse_args()

    toolkit = AuditToolkit(args.root)
    if args.command == "audit":
        result = toolkit.audit_traceability()
    elif args.command == "search":
        result = toolkit.search_evidence(args.query, args.limit)
    elif args.command == "trace":
        result = toolkit.get_traceability(args.source_id)
    elif args.command == "inspect-form":
        result = toolkit.inspect_form(args.form_name)
    else:
        result = toolkit.list_open_items()
    print(result)


if __name__ == "__main__":
    main()