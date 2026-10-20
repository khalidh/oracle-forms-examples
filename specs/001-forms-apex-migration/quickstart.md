# Migration Discovery and Validation Quickstart

This guide prepares read-only discovery and test design. It does not install APEX/ORDS, convert or overwrite Forms sources, create an APEX application, or modify the legacy schema/data.

## Prerequisites

- Obtain owner approval and a safe output directory outside the legacy source directory.
- Use the installed Oracle Forms 14.1.2 Home at `C:\Oracle\Middleware\Oracle_Home`.
- Confirm the Forms2XML syntax against the installed utility before running it.
- Use an isolated test database copy for any later CRUD or transaction test; do not run write tests against the source system.
- For an APEX 24.2 web validation environment, provision ORDS 23.3 or later and verify the APEX installation requirements.

## Export Forms modules for analysis

In PowerShell, set the Oracle Home and change to the approved export directory. The following command is a proposed read-only conversion invocation; it was not executed during plan generation:

```powershell
$env:ORACLE_HOME = 'C:\Oracle\Middleware\Oracle_Home'
Set-Location 'C:\path\to\approved\forms-xml-export'
& "$env:ORACLE_HOME\forms\templates\scripts\frmf2xml.bat" `
  'C:\path\to\oracle-forms-examples\QAFE_FORM1.fmb' 'USE_PROPERTY_IDS=YES' 'OVERWRITE=NO' 'DUMP=ALL'
```

Repeat for `QAFE_FORM2.fmb` and `QAFE_FORM3.fmb`. The utility writes `<module>_fmb.xml` in the current directory. Keep the FMB files unchanged; record the export command, utility version, date, and hashes. Inspect XML for blocks, items, canvases/windows, LOVs, record groups, relations, triggers, program units, menus, libraries, and called forms. If the installed utility reports a different option syntax, stop and follow its bundled help rather than guessing.

## Establish a read-only database baseline

Run approved `SELECT` statements in the test/reference schema and capture results with source identifiers. Record table/view row counts, key/foreign-key constraints, sequence definitions, invalid objects, package/trigger source, and database/APEX/ORDS versions. The local example baseline was 2,142 rows across 11 tables and three COURSE rows; it is not a production volume target.

Do not execute the repository SQL script again as a migration test: it contains INSERTs into computed view columns and DML trigger branches whose UPDATE/DELETE predicates are `WHERE 1 = 0`.

## Behavioral regression scenarios to define after export

For each confirmed Forms journey, write test cases with source IDs and expected database state:

1. Query with a matching criterion, no matches, and multiple matches; compare visible fields and navigation.
2. Create, update, and delete permitted records; verify persistence, related rows, generated IDs, audit columns, and rollback/error results.
3. Test `FIRST_NAME` null rejection and ZIP present/missing behavior from the observed SQL, then verify the exact Forms messages and timing from XML/runtime evidence.
4. Test the QAFE_FORM2 master-detail and ZIP LOV only after confirming the actual block relationships and selection behavior.
5. Test authorization using the approved role matrix; before approval, keep all business operations denied by default.
6. Test concurrent updates, lost-update handling, and transaction boundaries after documenting the current Forms commit/rollback behavior.

For every case, record preconditions, action, expected screen/result, expected persisted state, source object/event, execution result, and proof status in `docs/traceability-matrix.md` during the inventory phase.

## APEX environment gate

The reference PDB currently reports APEX 24.2.0 VALID and Database 19.3.0.0.0. Oracle documents APEX 24.2 for Database 19c or later and requires ORDS 23.3 or later. ORDS was not found under the local `C:\Oracle` tree; confirm the approved web tier, ORDS version, XML DB, memory settings, browser baseline, and deployment topology before any APEX web test. No application import/build is part of this quickstart.