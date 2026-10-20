# Migration Resume Checkpoint

## Resume 2026-10-20

- The CDB `ORCL` is `OPEN`; `ORACLE_FORMS_EXAMPLES` is `READ WRITE`; the listener is reachable on `127.0.0.1:1521`.
- ORDS 26.3 was restarted with the documented loopback-only command. Pool `forms_examples` is `VALID`; GET requests to `/ords/forms_examples/apex`, `/ords/forms_examples/apex_admin`, and `/i/apex_version.js?v=24.2.0` return HTTP 200. The Admin route returned 404 only for HEAD; GET succeeds.
- `ords install repair` remains unexecuted. Its last launch was cancelled, so do not run it without the owner's explicit confirmation. The missing proxied PL/SQL gateway mapping remains unresolved.
- Credentials from `.env.apex` were included in chat context on this date. Treat the affected APEX passwords as compromised and rotate them directly in APEX; never read or repeat the file contents.
- The owner updated `QAFE_DEMO_BUILDER` through Administration Services; the UI reported success and `LAST_UPDATE_DATE` is 2026-10-20 03:27:57 (DB clock). The account remains unlocked, has zero failed attempts, and retains App Builder-only privileges.
- Read-only APEX audit confirms `QAFE_DEMO_BUILDER` maps to workspace `QAFE_FORMS_DEMO`. The latest browser attempts returned `AUTHENTICATION_RESULT=8` / `Invalid Login Credentials`, including one after the user update. This is an internal-authentication credential rejection, not a workspace-name mismatch. The audit cannot establish whether the newly set value was entered identically at login.
- No detailed login submission appears in ORDS stdout or the available ORDS log directory; startup confirms pool `forms_examples` is `VALID` and logs a missing proxied PL/SQL gateway mapping. The mapping warning is not proven to cause the authentication rejection. Do not retry during the throttle period. If authorized, perform one controlled reset in Administration Services with an ASCII-only temporary value entered directly by the owner, then one browser login attempt; do not use an API or expose the value.
- Follow-up verification after the latest failed attempt confirms `APEX_WORKSPACES.WORKSPACE_ID` and `WWV_FLOW_FND_USER.SECURITY_GROUP_ID` are both `1800859919931476` for `QAFE_FORMS_DEMO` / `QAFE_DEMO_BUILDER`. The 2026-10-20 03:40:58 access-log entry records the same workspace and username with `Internal Authentication`, result 8. Workspace association is conclusively correct; the current failure is credential rejection.

## Clean Environment Progress — 2026-10-20

- The owner approved a side-by-side clean PDB and explicitly chose PDB/service/pool `QAFE_CLEAN`, workspace `QAFE_FORMS_CLEAN`, builder `QAFE_FORMS_BUILDER`, schema `STUDENT`; existing PDBs and `forms_examples` remain untouched.
- PDB `QAFE_CLEAN` is open read/write with a saved state; its service is `qafe_clean`. APEX 24.2.0 is `VALID` in this PDB. ORDS 26.3.0.r2721811 is installed and validated, and ORDS pool `qafe_clean` verifies `VALID` with PL/SQL Gateway `proxied`.
- ORDS setup required unlocking `APEX_PUBLIC_USER` only in `QAFE_CLEAN` and granting `EXECUTE ON SYS.DBMS_CRYPTO` to `ORDS_METADATA` there so `ORDS_UTIL` compiles. `/ords/qafe_clean/apex`, `/ords/qafe_clean/apex_admin`, and `/i/apex_version.js?v=24.2.0` return HTTP 200.
- `STUDENT_DATA` and schema `STUDENT` exist in the new PDB. The legacy DDL was imported with all `SYSTEM` tablespace clauses redirected to `STUDENT_DATA`, while 2,734 historical insert lines were excluded. Tables are empty. Some source Forms objects remain invalid: package body `STUDENT` has a `STUDENTOBJ` syntax issue; `V_EX01_01_STUDENT` and its trigger depend on missing `STUDENT_TEST`. Do not claim full legacy-schema validity.
- `.env.qafe-clean` (ignored and ACL-restricted) stores the local `STUDENT`, `PDBADMIN`, APEX REST, and ORDS runtime secrets. `.env.apex` has been normalized to the existing consumer keys `APEX_ADMIN_*` and `APEX_DEMO_*`, all pointing to `QAFE_CLEAN` / `QAFE_FORMS_CLEAN` / `QAFE_FORMS_BUILDER`; old workspace/PDB keys were removed. Secret values were not printed. `PDBADMIN` retains only its local `PDB_DBA` role and `CREATE SESSION`; temporary ORDS installer grants were revoked.
- APEX instance account `ADMIN` was created in `QAFE_CLEAN`; its secret is stored as `APEX_CLEAN_ADMIN_PASSWORD` in ignored ACL-restricted `.env.apex`.
- Workspace `QAFE_FORMS_CLEAN` was created through Administration Services and mapped to `STUDENT`. Builder `QAFE_FORMS_BUILDER` was created using the stored `APEX_CLEAN_BUILDER_PASSWORD`, then adjusted: workspace admin `No`, developer `Yes`, App Builder `Yes`, SQL Workshop `No`, Team Development `No`, accessible schemas `STUDENT`, account unlocked, no forced password change on first use. APEX reports “User QAFE_FORMS_BUILDER updated”; a read-only query confirmed this exact state.
- Builder login verified on 2026-10-20: the browser reached `/ords/qafe_clean/r/apex/workspace/home`, showing user `QAFE Forms Builder` in workspace `QAFE_FORMS_CLEAN` with App Builder available. The password remains only in ignored, ACL-restricted `.env.apex`. No APEX application has been created yet. Do not use the old workspace or old ORDS pool for this clean setup.
- Old-workspace inventory found zero APEX applications and four accounts (including three diagnostic accounts). No old accounts or applications were copied. The old `STUDENT` schema had 2,142 rows across its 11 source tables; only approved course rows 454, 455, and 456 were copied to the new PDB. All other historical rows, including student/contact, enrollment, grade, and ZIP data, remain only in the untouched old PDB. The new schema currently has 3 `COURSE` rows and zero rows in the other tables.
- `reset_apex_admin.ps1`, `reset_apex_demo_builder.ps1`, and `create_apex_demo_workspace.ps1` now target the clean PDB/workspace. `provision_apex_script_admin.ps1` and its SQL file remain legacy diagnostics for the old workspace; do not use them for the clean setup.

## QAFE_FORM1 Implementation Progress — 2026-10-20

- In response to the owner's request to continue despite open checklist items, built the first approved local migration slice in the clean workspace. Existing application 100 `QAFE Course Lookup` was retained; page 4 `Course Catalog` was added.
- Page 4 is an Interactive Report using `select course_no, description, cost from course order by course_no`. It exposes only the approved three columns, has no form page or DML process, requires APEX authentication, and runs through loopback-only ORDS pool `qafe_clean`.
- `F1-DEMO-01` passed on 2026-10-20: rows 454/455/456 displayed as English Grammar/30, Mathematics/20, and Dutch Grammar/40. Removed a transient session filter; saved the 10 rows-per-page choice as the Primary Default report for all users and verified it remained selected after reload. No write action was invoked.
- Application export is `apex/QAFE_MIGRATION.sql`; it was refreshed after the CRUD test and contains the secured, disabled page 6 harness. Supporting object definitions and original IDs were excluded.
- T018 is complete for this approved local QAFE_FORM1 slice only. Other US2 journeys, production authorization, full Forms behavioral equivalence, and the five unchecked specification checklist items remain open. Do not treat the broader US2 checkpoint as passed.
- ORDS is currently running on `127.0.0.1:8080` against the `qafe_clean` pool. Do not read `.env.apex` or `.env.qafe-clean`, and do not grant SYS inheritance privileges to export APEX packages.

## QAFE_FORM1 CRUD T021 Progress — 2026-10-20

- Owner approved a one-time CRUD test for `QAFE_FORMS_BUILDER` using only the marked disposable `COURSE` fixture in `QAFE_CLEAN`.
- Added page 6 `Course CRUD Test Harness` with authorization scheme `QAFE CRUD TEST BUILDER ONLY`, a region filter for the exact marker/creator, and custom PL/SQL that generates `COURSE_NO`, sets audit fields, and applies UPDATE/DELETE only to the marker row with a one-row count guard.
- Test results: created COURSE 457 at cost 15 with generated key and audit; updated cost to 25 while preserving creation audit and refreshing modification audit; deleted the row. SQL read-back confirmed zero remaining fixture rows and unchanged courses 454/455/456. COURSE_NO sequence value 457 was consumed.
- The duplicate primary-key case passed: `CRSE_PK` rejected a test insert using key 454; rollback left no test marker and COURSE 454 unchanged. Injected transaction-failure cases were not run. No ongoing write authorization was approved.
- `tests/acceptance/US4-validation.md` records the COURSE constraint subset; `tests/acceptance/platform-quality.md` defines current F1 keyboard, screen-reader, responsive, and browser scenarios. These platform scenarios remain unexecuted. `tests/acceptance/US6-slice-signoff.md` is prepared with owner acceptance pending.
- T028/T029/T030/T031/T034 are complete for the current QAFE_FORM1 local slice. T022 and T023 remain open globally for Form 3 validation and full event inventory; the Form 2 SQL validation/caller limits are documented. T024 and T027 are blocked for Form 2 by the owner’s no-data-access decision; T025/T026 are documented. T032/T033 require representative deployment data/approval.
- Page 6 was restored to `Commented Out` and `No URL Access`; `P6_COURSE_NO` checksum protection was restored. Direct runtime request returned `APEX.PAGE.NOT_FOUND`. Page 4 remains read-only.
- Refreshed export SHA-256: `3DBFB169928D85B841C4D66928B912664CBA3FAEA4A117F7A18431DDD0D16B20`.

## QAFE_FORM2 Porting Progress — 2026-10-20

- Owner authorized local Form 2 access to `QAFE_FORMS_BUILDER` in `QAFE_CLEAN`, including instructor/student fields and ongoing CRUD for INSTRUCTOR/STUDENT. COURSE/SECTION remain read-only; ZIPCODE is read-only for the LOV. Legacy and production data/network access remain prohibited.
- Application 100 pages 7-10 remain active with `QAFE_FORMS_BUILDER_ONLY` and checksum protection. Runtime create/update/delete passed on disposable INSTRUCTOR 115 and STUDENT 401; updates preserved creation audit and advanced modification audit. Both records were deleted, and the test tables are empty.
- Pages 11/13 are read-only COURSE/SECTION reports. Each Course Overview Description links to Section Overview with `P13_COURSE_NO`; the page filters `SECTION.COURSE_NO` and submits the item for refresh. Runtime `COURSE_NO=454` reached the expected empty state; positive matching details remain untested because SECTION is read-only and empty.
- The P8 ZIP LOV displayed `99999 - TESTVILLE, ZZ`; saving instructor 115 persisted `ZIP=99999`, confirmed by SQL. The synthetic INSTRUCTOR, STUDENT, and ZIPCODE rows were removed; INSTRUCTOR=0, STUDENT=0, SECTION=0, COURSE=3, and the marked ZIP=0 after cleanup.
- The official APEX export was refreshed from the Builder UI to `apex/QAFE_MIGRATION.sql`; SHA-256 `DE517C8C9F36082870F813A6685E6D37DBFC0E9E3E43C319EC5874E8DB74417F`. The export has not been imported elsewhere.
- The authenticated runtime session was confirmed as `QAFE_FORMS_BUILDER`. Student page 10 rejected a blank FIRST_NAME with `ORA-20101`; SQL read-back confirmed the original row and audit remained unchanged. No credentials were read or repeated.
- T025/T026 are complete. T027 remains in progress: runtime CRUD, ZIP selection/persistence, validation rejection, navigation, filter configuration, and the COURSE 454 empty-detail case are evidenced; a positive matching SECTION case and other related-data journeys remain open pending separate fixture approval. T022/T024 also remain open for broader validation and Form3 coverage.

## Resume Next Session — 2026-10-21

- Form 2 master-detail changes are saved in application 100: page 11 Description links set `P13_COURSE_NO` from `#COURSE_NO#` and clear page 13; page 13 has a protected Hidden item with per-request storage and filters `COURSE_NO = :P13_COURSE_NO`, submitting that item for report refresh.
- Runtime check passed for existing COURSE 454: the generated link passed `p13_course_no=454` and Section Overview showed `No data found.` No COURSE, SECTION, INSTRUCTOR, STUDENT, or ZIPCODE fixtures remain; counts are COURSE=3, SECTION=0, INSTRUCTOR=0, STUDENT=0, ZIPCODE=0.
- `apex/QAFE_MIGRATION.sql` was refreshed from the APEX Builder UI; SHA-256 is `DE517C8C9F36082870F813A6685E6D37DBFC0E9E3E43C319EC5874E8DB74417F`. It includes the page 11 link and page 13 filter. The export was not imported elsewhere.
- Browser state at pause: runtime session is on Section Overview for COURSE 454; Builder session is on Export Application for app 100. Sessions may expire; never read or request passwords in chat.
- First next step: ask the owner before creating a disposable SECTION fixture. Existing authorization keeps COURSE/SECTION read-only. If approved, create one minimal section linked to an existing approved course in `QAFE_CLEAN`, verify only that course's detail appears, then delete the fixture and confirm zero remaining rows. Without approval, preserve read-only behavior and leave positive-detail acceptance open.
- Remaining T027 gates include ZIP no-result/stale-value behavior, the null-FIRST_NAME insert case, return/unsaved-state navigation, and the positive related-detail case. No legacy PDB, production access, or network exposure is authorized.

**Checkpoint updated**: 2026-10-19 after the latest workspace login attempt. APEX reports “Password reset. Email sent.”, but the message is only queued: no SMTP service listens on localhost ports 25/465/587, the global APEX mail queue contains five messages with zero send attempts and no recorded errors, and the APEX mail log has no recent entries. The random-generated Builder password is unavailable. The owner performed a Provided reset, then the real browser login with the latest credential again returned `Invalid Login Credentials` and a 10-second throttle notice. The private API also returned status 1; the public API call from SYS was invalidated by `ORA-06598`, so it is not used as evidence. T017 remains complete; ORDS is loopback-only and routes return HTTP 200. Workspace login is unresolved; no APEX application or behavioral test exists yet. The ADMIN browser session has expired and its login form is ready with username `ADMIN` filled; no further password reset or login attempt was made.

## Completed and Saved

- Goal: migrate the three QAFE Oracle Forms examples to Oracle APEX using the Spec Kit plan in `specs/001-forms-apex-migration/`.
- T001 through T021 are marked complete for the current QAFE_FORM1 slice (21 of 34 tasks). T016 records broader US2 scenarios; it does not mean they passed. T021 includes only the guarded local harness and one-fixture run; the harness is disabled after testing.
- `F1-SRC-01` passes as a source-contract test: QAFE_FORM1 query source is `course`; block/item query flags are enabled; WHERE and ORDER BY are empty; startup runs `execute_query()`; COURSE_NO ColumnName is empty. This does not validate Forms runtime or APEX behavior.
- Local demo approval: authenticated users of the local demo workspace may read only `COURSE_NO`, `DESCRIPTION`, and `COST`, sorted by `COURSE_NO` ascending, 10 rows per page, using local sample course rows 454/455/456. All writes and non-loopback access remain denied; this is not production approval.
- Forms2XML exports and provenance are in `docs/forms-exports/`. Original FMB hashes were unchanged during export.
- US1 inventory, triggers, data model, behavior mapping, risks, and traceability are saved under `docs/`.
- APEX/ORDS environment evidence: `docs/apex-environment.md`.
- US2 acceptance scenarios: `tests/acceptance/US2-search.md`; defined, not executed.
- ORDS was restarted on 2026-10-19 with the complete restored APEX 24.2 image bundle; `/i/apex_version.js?v=24.2.0` and login routes returned HTTP 200.
- The APEX `ADMIN` instance account is usable for Administration Services. The owner updated `QAFE_DEMO_BUILDER` in that UI and made one manual workspace login attempt, which returned `Invalid Login Credentials`. Do not rely on `.env.apex` for workspace sign-in until a successful login is confirmed.
- `QAFE_FORMS_DEMO` exists and is mapped only to `STUDENT`. A read-only check found `QAFE_DEMO_BUILDER` has App Builder enabled and SQL Workshop disabled, but its Team Development flag is unexpectedly enabled. Do not use the elevated `QAFE_DEMO_SCRIPT_ADMIN` account for the demo.
- Diagnostic account `QAFE_DEMO_LOGIN_TEST` was created through Administration Services. A temporary full workspace-admin/developer profile did not change its APEX auth result (`AUTH_STATUS=1`). In a later controlled test, an Oracle-generated temporary password was applied to this test account with `APEX_UTIL.EDIT_USER`; the private `WWV_FLOW_FND_USER_INT.AUTHENTICATE` call still returned status 1. The test account was then locked and its component privileges restored to App Builder only (Y/N/N); the temporary password was not returned or saved outside the database. The primary `QAFE_DEMO_BUILDER` remains unlocked.
- Read-only account comparison on 2026-10-19 found all three workspace accounts (`QAFE_DEMO_BUILDER`, `QAFE_DEMO_LOGIN_TEST`, `QAFE_DEMO_SCRIPT_ADMIN`) in the expected workspace, unlocked, and with zero failed attempts. Their stored flags differ: Builder App Builder/SQL Workshop/Team Development = Y/N/Y; Login Test = Y/N/N; Script Admin = Y/Y/Y. The Builder Team Development flag contradicts the provisioning intent. `reset_apex_demo_builder.ps1` does not reset the SQL Workshop or Team Development flags. `QAFE_DEMO_SCRIPT_ADMIN` exists, but that alone does not establish a successful authentication check. `.env.apex.pending` exists; its contents and originating script were not inspected. No password or authentication retest was performed.
- Instance parameters were checked read-only: `APEX_BUILDER_AUTHENTICATION=APEX`, workspace/admin login enabled, `MAX_LOGIN_FAILURES=4`, and throttle delay 5 seconds by username+IP. All inspected accounts have the same password-version marker; workspace password date/lifespan are unset and change-on-first-use is disabled. No obvious global APEX login disablement explains the rejection. The next discriminating check requires a manual workspace login after a reset performed through Administration Services; enter the password only in the browser.
- After the Administration Services user update, one workspace login returned `Invalid Login Credentials` and the UI requested a 5-second wait. A read-only check afterward showed `QAFE_DEMO_BUILDER` remains unlocked with zero failed attempts, App Builder/SQL Workshop/Team Development = Y/N/N, change-on-first-use = N, and first-password-use = Y. No additional login attempt or password reset has been made. The stored credential itself cannot be verified from these metadata.
- The owner confirmed the password entered at workspace login was the same new value entered in both admin password fields. A one-shot SQL*Plus call to `wwv_flow_fnd_user_int.authenticate` using a hidden terminal prompt returned `AUTH_STATUS=1`; the password was not displayed or persisted by the test. Do not retry login. The dedicated admin Reset action was not reached; the admin session now needs sign-in again before using the UI reset route.
- The owner changed the Builder email and used `Randomly Generated`; APEX queued the notification, but it was not delivered because no local SMTP service listens. The owner then performed a **Provided** reset; the success message appeared. The latest browser login with the resulting credential returned `Invalid Login Credentials` and a 10-second throttle notice. The private `WWV_FLOW_FND_USER_INT.AUTHENTICATE` check returned status 1; the access log records result 8. APEX package source defines status 1 as an invalid username/password combination; 0 is success, 2 locked, 3 change required, and 9 delayed. The separate documented `APEX_WORKSPACE_USER.AUTHENTICATE` call from SYS failed with `ORA-06598` (insufficient `INHERIT PRIVILEGES`), so no privilege grant was made and that call is not a credential verdict. Both test accounts remain in the verified state: Builder unlocked with Y/N/N privileges; diagnostic account locked with Y/N/N. The ADMIN session expired before the proposed next controlled reset. Do not attempt another login during the throttle window.
- At this checkpoint no APEX application had been created. This status was superseded on 2026-10-20 by the `QAFE_FORM1 Implementation Progress` section above; `F1-DEMO-01` has since passed for the local slice only.

## Local Runtime

| Component | Saved state |
|---|---|
| Oracle Database | CDB `ORCL`, version 19.3.0.0.0 |
| Dedicated PDB / service | `ORACLE_FORMS_EXAMPLES` |
| APEX | 24.2.0, registry VALID in the dedicated PDB |
| Demo workspace | `QAFE_FORMS_DEMO`, mapped to `STUDENT` |
| Demo developer | `QAFE_DEMO_BUILDER`, App Builder only |
| ORDS | 26.3.0.r2721811; pool `forms_examples` |
| ORDS configuration / logs | `C:\Oracle\ORDS\config` / `C:\Oracle\ORDS\logs` |
| APEX media | `C:\Oracle\ORDS\apex-media\apex_24.2_en_restored_tar\apex\images` |
| Network boundary | Loopback only, `127.0.0.1:8080`; not a production deployment |

Workspace login: http://127.0.0.1:8080/ords/forms_examples/apex

Instance administration: http://127.0.0.1:8080/ords/forms_examples/apex_admin

Both login routes, `/i/apex_version.js?v=24.2.0`, `/i/favicon.ico`, and `/i/apex_ui/img/apex-logo.svg` returned HTTP 200 after the 2026-10-19 image restore. Authentication and business workflows have not been validated.

ORDS was stopped when this session resumed and has since been restarted in the current terminal. Do not assume it starts automatically after closing terminals or rebooting. If unavailable again, first check database/listener/PDB availability and whether port 8080 is already occupied. Do not start a second ORDS instance on an occupied port. To start the existing configuration when the port is free:

```powershell
& 'C:\Oracle\ORDS\dist\bin\ords.exe' --config 'C:\Oracle\ORDS\config' serve --port 8080 --ip-addresses 127.0.0.1 --apex-images 'C:\Oracle\ORDS\apex-media\apex_24.2_en_restored_tar\apex\images'
```

## Next After T021

1. Keep `QAFE_CLEAN` / `QAFE_FORMS_CLEAN` as the local preview target; do not use the old `ORACLE_FORMS_EXAMPLES` workspace or its unverified builder credentials.
2. Continue with any additional US2 journeys only after their actor, row/column scope, and test data are explicitly approved. `F1-DEMO-01` does not pass the broader US2 acceptance checkpoint.
3. Preserve the default-deny policy for production, ongoing writes, and network exposure. Do not grant SYS inheritance privileges to export APEX packages; the official UI export is `apex/QAFE_MIGRATION.sql`.
4. Injected transaction-failure CRUD tests remain open. The specification checklist still has five unchecked quality/readiness items; keep them open until reviewed rather than changing their markers during implementation.

## Gates and Known Issues

- General and production business operations remain default-deny. The local demo exception is authenticated-workspace read access for three COURSE columns only and does not authorize production access.
- The local demo uses only the three approved example course records. Do not turn this small demo dataset into a production fixture or query scope.
- Workspace login remains blocked for both `QAFE_DEMO_BUILDER` and the independently created `QAFE_DEMO_LOGIN_TEST`; both accounts are unlocked with zero failed attempts, but APEX's non-session authentication API returns invalid-credential status. Administration Services remains available to `ADMIN`. Stop password rotations and review instance/workspace authentication state before further application work.
- `apex_rest_config.sql` printed ORA-00942 while repairing supported objects. Login/static routes work, but REST functionality was not established; retain and investigate this warning before production.
- ORDS HTTP 570 / ORA-28000 was resolved by unlocking `APEX_PUBLIC_USER` only in the dedicated PDB. Do not modify corresponding accounts in other PDBs.
- Several SQL view UPDATE/DELETE trigger branches use `WHERE 1 = 0`; resolve before CRUD implementation. Form 3 cost boundary and COURSE_NO validation fetch target also need owner decisions.
- Keep APEX 24.2 as the current baseline. Do not select APEX 26.2 on the current 19.3 database without addressing its documented newer RU requirement.

## Preservation and Secrets

- Work is saved in the working tree but has not been committed. Git currently lists `.github/`, `.specify/`, `.gitignore`, `docs/`, `specs/`, `apex/`, `tests/`, and generated Forms/runtime artifacts as untracked. Do not delete or overwrite them as cleanup.
- `.env` exists and `git check-ignore .env` succeeded at pause. Never print its contents or copy secrets into documentation, chat, memory, exports, or commits.
- `.env.apex` is ignored by Git and ACL-restricted to the current Windows account, SYSTEM, and Administrators. Never print its contents or copy its password into documentation, chat, memory, exports, or commits.
- This checkpoint is documentation, not a database backup or application export. No new backup or commit was made for the pause.
- On request to resume, start from T017 rather than reinstalling APEX/ORDS or repeating the inventory.