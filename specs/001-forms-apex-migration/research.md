# Research: Migration Oracle Forms vers Oracle APEX

**Date**: 2026-10-18  
**Scope**: Planification seulement; aucune conversion, installation, modification de schema ou de donnee n'a ete executee.

## Decision 1: Baseline Oracle APEX

**Decision**: Utiliser Oracle APEX 24.2 comme baseline de conception, car le registre local du PDB de reference declare `Oracle APEX 24.2.0` en statut `VALID`. Cibler Oracle Database 19c; l'instance locale rapporte 19.3.0.0.0. Pour un environnement web testable, ORDS 23.3 ou plus recent est requis par APEX 24.2 et n'a pas ete trouve sous `C:\Oracle` lors de la recherche.

**Rationale**: Le guide officiel APEX 24.2 exige Oracle Database 19c ou ulterieur; cette baseline evite de choisir une version APEX qui demanderait une mise a niveau RU non approuvee. La compatibilite doit encore etre verifiee sur l'environnement cible et ses correctifs, XML DB et parametres memoire.

**Alternatives considered**:
- APEX 26.2: release plus recente, mais son guide exige Oracle Database 19c RU 19.18 ou plus recent; l'environnement local expose 19.3 et aucune ligne de patch SQL n'a ete trouvee. Ne pas retenir sans plan approuve de patching.
- Une release APEX anterieure: non necessaire pour la baseline locale tant que APEX 24.2 est installe; ne la choisir que si les contraintes de support/deploiement l'exigent.

**Sources**:
- Oracle APEX 24.2 Installation Requirements: https://docs.oracle.com/en/database/oracle/apex/24.2/htmig/apex-installation-requirements.html
- Oracle APEX 26.2 Installation Requirements (alternative): https://docs.oracle.com/en/database/oracle/apex/26.2/htmig/apex-installation-requirements.html
- Oracle APEX 24.2 form types: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/understanding-forms-types.html

## Decision 2: Extract Forms behavior before mapping

**Decision**: Require a read-only Forms2XML export of all three `.fmb` modules before freezing page, block, item, LOV, relation, trigger, menu, program-unit, and called-form inventories. Use stable property identifiers and full property dumps. Treat the generated XML and images as derived analysis artifacts; preserve the original `.fmb` files byte-for-byte.

**Rationale**: The repository has only binary `.fmb` sources and high-level README summaries. No internal component names or detailed trigger behavior can be reliably inferred from those binaries. The local Forms 14.1.2 Oracle Home contains `forms\templates\scripts\frmf2xml.bat` plus `frmxmltools.jar`, `frmjdapi.jar`, and `xmlparserv2.jar`.

**Candidate invocation for a future approved discovery task (not executed in this plan)**:

```powershell
$env:ORACLE_HOME = 'C:\Oracle\Middleware\Oracle_Home'
Set-Location 'C:\path\to\approved\export-directory'
& "$env:ORACLE_HOME\forms\templates\scripts\frmf2xml.bat" `
  'C:\path\to\QAFE_FORM1.fmb' 'USE_PROPERTY_IDS=YES' 'OVERWRITE=NO' 'DUMP=ALL'
```

Run once per FMB (or pass multiple input files if supported by the bundled utility version). The launcher writes XML into the current directory. Validate help/syntax with the installed 14.1.2 bundle before use; do not write output over the repository originals. The workspace currently contains no `.fmb.xml` exports.

**Alternatives considered**:
- Manual inference from README: insufficient for triggers, items, relationships, menus, and runtime validation; rejected as a basis for a complete migration.
- Compile output `.fmx` and `.err`: useful diagnostics only, not a substitute for source component export.

**Sources**:
- Oracle Forms and Reports 14.1.2 documentation: https://docs.oracle.com/en/middleware/developer-tools/forms/14.1.2/index.html
- Oracle Forms2XML utility documentation: https://docs.oracle.com/en/middleware/developer-tools/forms/14.1.2/develop-forms/using-forms2xml-utility.html

## Decision 3: Map behavior, not widget appearance

**Decision**: After export, map each confirmed user journey and data relationship to the simplest suitable APEX interaction. Candidate forms include single-row forms, report-with-form, editable interactive grids, and one-page or drill-down master-detail pages. These are candidate components only; no one-to-one equivalence with Forms is assumed.

**Rationale**: Oracle APEX documents these as distinct page patterns. The README says Form 2 has grids, a ZIP LOV, and master-detail behavior, but the FMB export must establish which data blocks, buttons, conditions, and flows actually participate.

**Alternatives considered**:
- Recreate the desktop canvas pixel-for-pixel: rejected; the spec requires preserving user outcomes and documenting necessary desktop-to-web changes.
- Generate pages automatically from tables before confirming behavior: rejected; it risks losing custom trigger, navigation, and validation logic.

**Sources**:
- APEX 24.2 form types: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/understanding-forms-types.html
- APEX 24.2 master-detail: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/managing-master-detail-forms.html

## Decision 4: Transactions, concurrency, and security

**Decision**: Inventory Forms commit/rollback and error events from XML and SQL before defining APEX page-processing boundaries. Use explicit server-side validation and the least-privilege, default-deny policy already approved in the spec. Evaluate lost-update protection for each editable form/grid after concurrency requirements are confirmed.

**Rationale**: APEX form DML and page processing have their own transaction and commit behavior; silently mapping a Forms trigger to a browser interaction may change transaction outcomes. APEX provides lost-update detection options, but the correct mode depends on table design and multi-table edits.

**Alternatives considered**:
- Rely on hidden/disabled controls for authorization: rejected; authorization must be enforced server-side.
- Assume automatic row processing exactly matches Forms: rejected; behavior and transaction boundaries require regression tests.

**Sources**:
- APEX 24.2 page processing: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/how-does-page-processing-and-page-rendering-work.html
- APEX 24.2 lost-update detection: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/configuring-lost-update-detection.html
- APEX 24.2 application security: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/managing-application-security.html

## Decision 5: Contracts and deployment topology

**Decision**: Do not create API contracts yet: no external HTTP/API contract is visible in the repository. Treat ORDS installation/configuration, browser support, target patch level, production data volumes, deployment, backup, rollback, audit, and logging as explicit environment gates for later owner review.

**Rationale**: The available sources are Forms modules and a local schema script. ORDS was not found under `C:\Oracle`; its absence there does not establish that no external deployment exists.

**Alternatives considered**:
- Assume Forms WebLogic supplies APEX web serving: rejected; APEX 24.2 requires ORDS 23.3+ according to Oracle documentation.
- Invent REST endpoints: rejected because no external service contract is present.

**Sources**:
- Oracle APEX 24.2 web server requirements: https://docs.oracle.com/en/database/oracle/apex/24.2/htmig/apex-installation-requirements.html
- Oracle APEX 24.2 deployment: https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/understanding-the-deployment-process.html