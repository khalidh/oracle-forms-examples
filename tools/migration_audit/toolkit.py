"""Bounded, read-only tools for local migration evidence review."""

from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any


_ALLOWED_DIRECTORIES = ("docs", "specs", "tests", "script")
_ALLOWED_SUFFIXES = {".md", ".sql", ".xml"}
_MAX_SEARCH_RESULTS = 25
_MAX_EXCERPT_LENGTH = 400
_SOURCE_ID = re.compile(r"^[A-Z0-9]+(?:-[A-Z0-9]+)+$")
_FORM_NAMESPACE = "http://xmlns.oracle.com/Forms"
_FORM_EXPORTS = {
    "QAFE_FORM1": "docs/forms-exports/QAFE_FORM1_fmb.xml",
    "QAFE_FORM2": "docs/forms-exports/QAFE_FORM2_fmb.xml",
    "QAFE_FORM3": "docs/forms-exports/QAFE_FORM3_fmb.xml",
}


def _form_attribute(element: ET.Element, name: str) -> str:
    return element.attrib.get(f"{{{_FORM_NAMESPACE}}}{name}", "")


def _json_result(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2)


def _table_rows(path: Path) -> list[tuple[int, list[str]]]:
    if not path.is_file():
        return []

    headers: list[str] | None = None
    rows: list[tuple[int, list[str]]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if not line.strip().startswith("|"):
            continue

        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if all(not cell or set(cell) <= {"-", ":"} for cell in cells):
            continue
        if headers is None:
            headers = cells
            continue
        if len(cells) == len(headers):
            rows.append((line_number, cells))

    return rows


class AuditToolkit:
    """Expose only approved local documents through read-only operations."""

    def __init__(self, root: Path) -> None:
        self.root = root.resolve()

    def _source_files(self):
        for directory in _ALLOWED_DIRECTORIES:
            base = self.root / directory
            if not base.is_dir():
                continue
            for path in sorted(base.rglob("*")):
                if path.is_file() and not path.is_symlink() and path.suffix.lower() in _ALLOWED_SUFFIXES:
                    resolved = path.resolve()
                    if resolved.is_relative_to(self.root):
                        yield resolved

    def search_evidence(self, query: str, limit: int = 10) -> str:
        """Search approved project text and return excerpts with file paths and line numbers."""
        normalized_query = query.strip()[:200]
        if not normalized_query:
            return _json_result({"query": query, "matches": [], "error": "query must not be empty"})

        bounded_limit = max(1, min(limit, _MAX_SEARCH_RESULTS))
        matches: list[dict[str, Any]] = []
        found_more = False
        for path in self._source_files():
            text = path.read_text(encoding="utf-8", errors="replace")
            for line_number, line in enumerate(text.splitlines(), 1):
                if normalized_query.casefold() not in line.casefold():
                    continue
                if len(matches) >= bounded_limit:
                    found_more = True
                    break
                matches.append(
                    {
                        "path": path.relative_to(self.root).as_posix(),
                        "line": line_number,
                        "text": line[:_MAX_EXCERPT_LENGTH],
                    }
                )
            if found_more:
                break

        return _json_result(
            {"query": normalized_query, "matches": matches, "truncated": found_more}
        )

    def get_traceability(self, source_id: str) -> str:
        """Return one traceability row by source identifier, without interpreting its status."""
        normalized_id = source_id.strip().upper()
        if not _SOURCE_ID.fullmatch(normalized_id):
            return _json_result({"source_id": source_id, "found": False, "error": "invalid source identifier"})

        matrix = self.root / "docs" / "traceability-matrix.md"
        for line_number, cells in _table_rows(matrix):
            if cells and cells[0].strip("` ").upper() == normalized_id:
                return _json_result(
                    {
                        "source_id": normalized_id,
                        "path": matrix.relative_to(self.root).as_posix(),
                        "line": line_number,
                        "row": cells,
                    }
                )
        return _json_result({"source_id": normalized_id, "found": False})

    def inspect_form(self, form_name: str) -> str:
        """Read structured block, item, and trigger evidence from a known Forms XML export."""
        normalized_name = form_name.strip().upper()
        export_path = _FORM_EXPORTS.get(normalized_name)
        if export_path is None:
            return _json_result(
                {"form_name": normalized_name, "found": False, "error": "unknown Forms module"}
            )

        path = (self.root / export_path).resolve()
        if not path.is_relative_to(self.root) or not path.is_file():
            return _json_result(
                {"form_name": normalized_name, "found": False, "error": "Forms XML export is missing"}
            )

        tree = ET.parse(path)
        namespace = f"{{{_FORM_NAMESPACE}}}"
        module = tree.getroot().find(f"{namespace}FormModule")
        if module is None:
            return _json_result(
                {"form_name": normalized_name, "found": False, "error": "FormModule is missing"}
            )

        blocks: list[dict[str, Any]] = []
        for block in module.findall(f"{namespace}Block"):
            items = [
                {
                    "name": _form_attribute(item, "Name"),
                    "column_name": _form_attribute(item, "ColumnName"),
                    "prompt": _form_attribute(item, "Prompt"),
                    "query_allowed": _form_attribute(item, "QueryAllowed"),
                    "visible": _form_attribute(item, "Visible"),
                }
                for item in block.findall(f"{namespace}Item")
            ]
            triggers = [
                {
                    "name": _form_attribute(trigger, "Name"),
                    "text": _form_attribute(trigger, "TriggerText"),
                }
                for trigger in block.findall(f"{namespace}Trigger")
            ]
            blocks.append(
                {
                    "name": _form_attribute(block, "Name"),
                    "query_source": _form_attribute(block, "QueryDataSourceName"),
                    "query_allowed": _form_attribute(block, "QueryAllowed"),
                    "where_clause": _form_attribute(block, "WhereClause"),
                    "order_by_clause": _form_attribute(block, "OrderByClause"),
                    "maximum_records_fetched": _form_attribute(block, "MaximumRecordsFetched"),
                    "items": items,
                    "triggers": triggers,
                }
            )

        form_triggers = [
            {
                "name": _form_attribute(trigger, "Name"),
                "text": _form_attribute(trigger, "TriggerText"),
            }
            for trigger in module.findall(f"{namespace}Trigger")
        ]
        return _json_result(
            {
                "form_name": normalized_name,
                "path": path.relative_to(self.root).as_posix(),
                "blocks": blocks,
                "form_triggers": form_triggers,
            }
        )

    def audit_traceability(self) -> str:
        """Report every test-record link in the traceability matrix as present or missing."""
        matrix = self.root / "docs" / "traceability-matrix.md"
        entries: list[dict[str, Any]] = []
        for line_number, cells in _table_rows(matrix):
            if len(cells) < 7:
                continue
            source_id = cells[0].strip("` ")
            test_match = re.search(r"`([^`]+)`", cells[5])
            test_record = test_match.group(1) if test_match else ""
            resolved_test = (self.root / test_record).resolve() if test_record else None
            exists = bool(
                resolved_test
                and resolved_test.is_relative_to(self.root)
                and resolved_test.is_file()
            )
            entries.append(
                {
                    "source_id": source_id,
                    "matrix_line": line_number,
                    "test_record": test_record or None,
                    "test_exists": exists,
                    "proof_status": cells[6],
                }
            )

        missing = [entry for entry in entries if not entry["test_exists"]]
        return _json_result(
            {
                "matrix": "docs/traceability-matrix.md",
                "total_entries": len(entries),
                "existing_test_records": len(entries) - len(missing),
                "test_records": entries,
                "missing_test_records": missing,
            }
        )

    def list_open_items(self) -> str:
        """List recorded open risks and traceability entries needing proof or review."""
        risks_path = self.root / "docs" / "migration-risks.md"
        open_risks: list[dict[str, str]] = []
        for _, cells in _table_rows(risks_path):
            if len(cells) >= 6 and cells[5].strip().casefold() not in {"closed", "resolved"}:
                open_risks.append({"id": cells[0], "item": cells[1], "status": cells[5]})

        traceability_path = self.root / "docs" / "traceability-matrix.md"
        unverified: list[dict[str, str]] = []
        review_terms = re.compile(
            r"\b(?:unknown|unverified|not tested|open|needs owner)\b",
            re.IGNORECASE,
        )
        for _, cells in _table_rows(traceability_path):
            if len(cells) >= 7 and review_terms.search(cells[6]):
                unverified.append({"source_id": cells[0], "proof_status": cells[6]})

        return _json_result({"open_risks": open_risks, "unverified_traceability": unverified})