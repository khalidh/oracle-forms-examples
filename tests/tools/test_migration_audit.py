import json
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.migration_audit import AuditToolkit


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class AuditToolkitTests(unittest.TestCase):
    def setUp(self) -> None:
        self.toolkit = AuditToolkit(REPOSITORY_ROOT)

    def test_search_returns_source_path_and_line_number(self) -> None:
        result = json.loads(self.toolkit.search_evidence("F3-TR-03"))

        self.assertTrue(result["matches"])
        allowed_roots = ("docs/", "specs/", "tests/", "script/")
        self.assertTrue(
            all(match["path"].startswith(allowed_roots) for match in result["matches"])
        )
        self.assertTrue(all(match["line"] > 0 for match in result["matches"]))

    def test_search_excludes_environment_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docs = root / "docs"
            docs.mkdir()
            (docs / "notes.md").write_text("public note", encoding="utf-8")
            (docs / ".env").write_text("AUDIT_TEST_SECRET_MARKER", encoding="utf-8")

            result = json.loads(AuditToolkit(root).search_evidence("AUDIT_TEST_SECRET_MARKER"))

        self.assertEqual([], result["matches"])

    def test_traceability_lookup_preserves_source_status(self) -> None:
        result = json.loads(self.toolkit.get_traceability("F3-TR-03"))

        self.assertEqual("F3-TR-03", result["source_id"])
        self.assertIn("Observed XML", result["row"][-1])
        self.assertGreater(result["line"], 0)

    def test_form_inspection_returns_structured_qafe_form1_query_facts(self) -> None:
        result = json.loads(self.toolkit.inspect_form("QAFE_FORM1"))
        course = next(block for block in result["blocks"] if block["name"] == "COURSE")
        items = {item["name"]: item for item in course["items"]}

        self.assertEqual("docs/forms-exports/QAFE_FORM1_fmb.xml", result["path"])
        self.assertEqual("course", course["query_source"])
        self.assertEqual("true", course["query_allowed"])
        self.assertEqual("", course["where_clause"])
        self.assertEqual("", course["order_by_clause"])
        self.assertTrue(all(item["query_allowed"] == "true" for item in items.values()))
        self.assertEqual("", items["COURSE_NO"]["column_name"])
        startup = next(trigger for trigger in result["form_triggers"] if trigger["name"] == "WHEN-NEW-FORM-INSTANCE")
        self.assertIn("execute_query()", startup["text"])

    def test_form_inspection_rejects_unknown_module(self) -> None:
        result = json.loads(self.toolkit.inspect_form("../../.env"))

        self.assertFalse(result["found"])
        self.assertEqual("unknown Forms module", result["error"])

    def test_traceability_audit_reports_missing_acceptance_files(self) -> None:
        result = json.loads(self.toolkit.audit_traceability())

        self.assertGreater(result["total_entries"], 0)
        self.assertEqual(result["total_entries"], len(result["test_records"]))
        self.assertTrue(all("test_exists" in entry for entry in result["test_records"]))
        self.assertTrue(result["missing_test_records"])
        self.assertTrue(all(not entry["test_exists"] for entry in result["missing_test_records"]))

    def test_open_items_include_recorded_blockers(self) -> None:
        result = json.loads(self.toolkit.list_open_items())
        risk_ids = {risk["id"] for risk in result["open_risks"]}

        self.assertIn("R-08", risk_ids)
        self.assertTrue(result["unverified_traceability"])

    def test_agent_adapter_registers_only_read_only_tools(self) -> None:
        fake_framework = types.ModuleType("agent_framework")

        class FakeAgent:
            def __init__(self, **kwargs: object) -> None:
                self.options = kwargs

        fake_framework.Agent = FakeAgent
        with patch.dict(sys.modules, {"agent_framework": fake_framework}):
            from tools.migration_audit.agent import create_audit_agent

            agent = create_audit_agent(object(), REPOSITORY_ROOT)

        self.assertEqual("MigrationAuditAgent", agent.options["name"])
        self.assertEqual(5, len(agent.options["tools"]))
        self.assertTrue(all(callable(tool) for tool in agent.options["tools"]))


if __name__ == "__main__":
    unittest.main()