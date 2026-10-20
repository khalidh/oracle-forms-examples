# US1 Inventory Acceptance Record

**Feature**: `001-forms-apex-migration`  
**Reviewed**: 2026-10-18  
**Status**: Source traceability review passed; independent business-owner approval remains open.  
**Write scope**: Derived XML and documentation only. Original FMB, schema, and data were not modified.

## Acceptance Results

| ID | Check | Expected | Observed | Status |
|---|---|---|---|---|
| US1-AC-01 | Source inventory | Three FMB modules, README, and SQL script are identified. | `QAFE_FORM1/2/3.fmb`, `README.md`, `script/student-db-script.sql` are present. | PASS |
| US1-AC-02 | Forms2XML exports | One parsed XML export per FMB; sources remain unchanged. | Forms2XML 14.1.2 produced three XML files; source hashes checked before/after. | PASS |
| US1-AC-03 | Provenance register | Source/export hashes, sizes, options, version, and date recorded. | Register in `docs/forms-exports/README.md` includes hashes, byte sizes, 14.1.2, DUMP=ALL, USE_PROPERTY_IDS=YES, OVERWRITE=NO. | PASS |
| US1-AC-04 | Component traceability | Blocks, items, triggers, windows/canvases, LOVs, relations, record groups, and program units are inventoried or marked unknown. | XML parsed: Form 1 1 block/8 items/3 triggers; Form 2 4 blocks/47 items/11 triggers/3 canvases/3 windows/1 LOV/1 relation/1 record group/3 program units; Form 3 3 blocks/24 items/8 triggers/2 canvases/2 windows/1 program unit. | PASS |
| US1-AC-05 | SQL traceability | Declared tables, views, keys, sequences, types/packages, triggers, and missing dependencies are cited. | `docs/data-model.md` and `docs/trigger-analysis.md` cite the supplied SQL objects and explicitly identify `STUDENT_TEST` as missing from the supplied DDL. | PASS |
| US1-AC-06 | No invented behavior | Unverified bindings and contradictory SQL behavior remain identified as unknown or owner decisions. | `docs/forms-inventory.md`, `docs/migration-mapping.md`, `docs/migration-risks.md` distinguish XML/SQL evidence from behavior still requiring runtime or owner confirmation. | PASS |
| US1-AC-07 | Read-only legacy boundary | Source modules, database schema, and records remain unchanged by discovery. | FMB hashes unchanged after conversion; no database writes performed during this inventory task. | PASS |

## Source Hashes

| FMB | SHA-256 before/after export |
|---|---|
| `QAFE_FORM1.fmb` | `4C9EBAC6E730FBD502A65CE2A58EC33287E4B604929979F18D69E610BFBBF3D6` |
| `QAFE_FORM2.fmb` | `43DB95278C9D996DE602A1D0533609B7115FF502D585D6642595834224D3CDCA` |
| `QAFE_FORM3.fmb` | `2CD4FF34498036B2ED10564677394ECABA583CCB5BB31CA2CE0A8BBBF2AF4120` |

## Open Owner Review

- Confirm the intended behavior of Forms CRUD flags versus SQL view triggers with UPDATE/DELETE `WHERE 1 = 0`.
- Confirm the Form 3 SECTION.COURSE_NO validation fetch target and the cost threshold at exactly 5.
- Confirm identities, roles, external libraries/calls, production schema equivalence, and any dependencies outside this repository.
- This evidence review is not a business-owner sign-off and does not authorize application implementation, database changes, or Forms retirement.# US1 Inventory Acceptance Record

**Feature**: `001-forms-apex-migration`  
**Reviewed**: 2026-10-18  
**Review status**: Source traceability pass; business-owner approval and full behavioral coverage remain open.  
**Write scope**: Derived XML and documentation only. No FMB, schema, or data was modified.

## Evidence Checks

| ID | Check | Expected result | Observed result | Status |
|---|---|---|---|---|
| US1-AC-01 | Confirm source modules and SQL/documentation are present. | All three named FMB files, README, and student SQL script are listed. | `QAFE_FORM1/2/3.fmb`, `README.md`, and `script/student-db-script.sql` exist. | PASS |
| US1-AC-02 | Export each FMB with Forms2XML and preserve its source. | One XML per FMB; each original FMB hash remains unchanged. | Three XML exports are present in `docs/forms-exports/`; pre/post source hashes matched. | PASS |
| US1-AC-03 | Record export provenance. | Tool version, options, source hashes, output hashes, sizes, and review status are recorded. | Register records Forms2XML 14.1.2, DUMP=ALL, USE_PROPERTY_IDS=YES, OVERWRITE=NO, hashes, sizes, and review status. | PASS |
| US1-AC-04 | Inventory Forms objects from XML rather than inference. | Blocks, items, triggers, windows, canvases, LOV, relation, program units, and record group are enumerated per module. | Form 1: 1 block/8 items/3 triggers; Form 2: 4 blocks/3 canvases/3 windows/1 LOV/1 record group/1 relation/3 program units/11 triggers; Form 3: 3 blocks/2 canvases/2 windows/1 program unit/8 triggers. | PASS |
| US1-AC-05 | Trace database facts to SQL source objects. | Tables/views/keys/triggers and unresolved dependencies reference the supplied SQL. | `docs/data-model.md` and `docs/trigger-analysis.md` cite tables, views, declared keys, trigger names, and the `STUDENT_TEST` gap. | PASS |
| US1-AC-06 | Avoid converting unknowns into facts. | Missing runtime bindings, external dependencies, and contradictory DML are clearly marked. | Form-level commit behavior, external libraries/calls, production schema equivalence, user roles, and the CRUD discrepancy remain explicit open gates. | PASS |
| US1-AC-07 | Confirm no legacy write or source conversion occurred. | Original FMB hashes are unchanged; no database mutation is part of this record. | FMB hashes were checked after export; no database command was run in this US1 export/analysis session. | PASS |

## Inventory Coverage

- All 22 exported Forms triggers are listed by module and event in `docs/trigger-analysis.md` (Form 1: 3, Form 2: 11, Form 3: 8).
- DML flags, block query sources, items, navigation, LOV mapping, record-group SQL, relation join, and program-unit names are recorded in `docs/forms-inventory.md` and `specs/001-forms-apex-migration/data-model.md`.
- The SQL inventory contains 11 tables, 7 views, 5 sequences, 5 types, and the packages/body source described in the provided script. This is not asserted to be the complete production schema.
- No `.pll`, `.plx`, `.mmb`, `.mmx`, `.olb`, `.fmt`, prior XML export, deployment config, or screenshots were present among the repository source files reviewed.

## Open Review Items

- Owner must confirm whether the documented CRUD behavior is intended for all editable Forms blocks and approve remediation of the SQL view triggers whose UPDATE/DELETE branches use `WHERE 1 = 0`.
- Owner must confirm the Form 3 COURSE_NO validation fetch target and cost threshold at exactly 5.
- Owner must supply or identify external authentication, database grants, linked libraries, runtime deployment, production data volumes, and any other Forms modules/dependencies outside this repository.
- A second-person business review is not recorded. Do not treat this source inventory acceptance as approval of migration semantics or retirement of Forms.