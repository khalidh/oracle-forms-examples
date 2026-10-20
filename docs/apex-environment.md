# APEX Environment Baseline

## Observed Local Reference

| Component | Observed value | Evidence / status |
|---|---|---|
| Oracle Database | 19c, version 19.3.0.0.0 | Local `V$VERSION`; APEX 24.2 supports 19c or later. Not assumed to be the production target. |
| Oracle APEX | 24.2.0, `VALID` | Installed and verified in `ORACLE_FORMS_EXAMPLES`; other PDBs were not changed by this setup. |
| PDB | `ORACLE_FORMS_EXAMPLES` | Dedicated local development PDB; not a production environment. |
| ORDS | 26.3.0.r2721811 | Installed in `C:\Oracle\ORDS\dist`; standalone config at `C:\Oracle\ORDS\config`; pool `forms_examples` targets `127.0.0.1:1521/ORACLE_FORMS_EXAMPLES`. |
| ORDS web endpoint | `http://127.0.0.1:8080/ords/forms_examples/` | Standalone binds loopback only. `apex` and `apex_admin` return HTTP 200; `/i/favicon.ico` and `/i/apex_ui/img/apex-logo.svg` return HTTP 200. |
| APEX static images | `C:\Oracle\ORDS\apex-media\apex_24.2_en_restored_tar\apex\images` | Restored from the intact local `apex_24.2_en.retry.zip` because the former images directory was missing 15,900 of 26,913 files. `/i/apex_version.js?v=24.2.0` now returns HTTP 200. |
| Local demo workspace | `QAFE_FORMS_DEMO` mapped to schema `STUDENT` | Created on 2026-10-19. A read-only account check found `QAFE_DEMO_BUILDER` unlocked with zero failed attempts, App Builder enabled, SQL Workshop disabled, but the Team Development flag enabled. This conflicts with the provisioning intent; browser sign-in remains rejected and its password is unverified. |
| Diagnostic developer | `QAFE_DEMO_LOGIN_TEST` in `QAFE_FORMS_DEMO` | Created through Administration Services. Unlocked with zero failed attempts; App Builder enabled, SQL Workshop and Team Development disabled. A temporary full developer/admin profile did not change authentication and was reverted; APEX's authentication API rejected this account too. |
| Script diagnostic account | `QAFE_DEMO_SCRIPT_ADMIN` in `QAFE_FORMS_DEMO` | A read-only account check found it unlocked with zero failed attempts and App Builder, SQL Workshop, and Team Development enabled. Its presence does not prove the script's authentication check passed. `.env.apex.pending` exists, but its contents were not inspected. Do not use this elevated account for the demo. |
| ORDS REST configuration | `APEX_PUBLIC_USER` proxy target unlocked in this PDB | Required after ORDS returned ORA-28000; do not unlock or alter corresponding users in other PDBs. |
| Oracle XML DB | 19.0.0.0.0, `VALID` | `DBA_REGISTRY` in the dedicated PDB. |
| Memory / workarea | SGA_TARGET 5033164800; PGA_AGGREGATE_TARGET 1677721600; WORKAREA_SIZE_POLICY AUTO | Local initialization; satisfies APEX 24.2 documented memory minimums. |
| Browser / volume / performance | Not specified | Owner confirmation and representative baseline required. |

Oracle's APEX 24.2 installation guide lists Database 19c or later and ORDS 23.3 or later. APEX 26.2 is not selected: its guide requires Database 19c RU 19.18 or later, while this local instance reports 19.3.

`apex_rest_config.sql` created `APEX_LISTENER` and `APEX_REST_PUBLIC_USER` and set the proxy relationship. It also printed `ORA-00942` during its best-effort repair of APEX-supported database objects; APEX registry remains VALID and the tested login routes/static assets return HTTP 200. Record and investigate this warning before any production deployment.

## Current Clean Destination (2026-10-20)

| Component | Value | Status |
|---|---|---|
| PDB / service | `QAFE_CLEAN` / `qafe_clean` | Open read/write; saved state |
| APEX | 24.2.0 | `VALID` |
| ORDS / pool | 26.3.0.r2721811 / `qafe_clean` | `VALID`; gateway proxied; loopback routes return HTTP 200 |
| Workspace / builder | `QAFE_FORMS_CLEAN` / `QAFE_FORMS_BUILDER` | Login verified; admin disabled, App Builder only |
| Schema / tablespace | `STUDENT` / `STUDENT_DATA` | DDL imported; legacy source objects noted below |
| Migrated records | `STUDENT.COURSE` 454, 455, 456 | Only approved records; all other new schema tables remain empty |

Old `ORACLE_FORMS_EXAMPLES`, `forms_examples`, `QAFE_FORMS_DEMO`, its four accounts, and its historical `STUDENT` data remain intact. The old workspace had no APEX applications. No applications or user accounts were migrated. The new `.env.apex` uses the existing `APEX_ADMIN_*` and `APEX_DEMO_*` keys for the clean destination; secret values are not documented.

The legacy import contains three known invalid objects: package body `STUDENT` (`STUDENTOBJ` parse error), view `V_EX01_01_STUDENT` (missing `STUDENT_TEST`), and its trigger. The clean builder login was verified, but no APEX application has yet been created or behavior-tested.

## Environment Gate

The local reference is a non-production candidate. Before migration acceptance or exposure beyond loopback, an owner must approve the target DB/PDB and RU, production authentication and authorization matrix, network boundary/TLS, backups, logging, and test-data policy. The ORDS pool is named `forms_examples`; it is not exposed beyond `127.0.0.1`. The local demo workspace exists; its APEX application has not yet been created.

On 2026-10-19, ORDS was restarted with the restored image path above and remained bound to `127.0.0.1:8080`. Static asset checks returned 200. No workspace or application was created in this recovery step.

The local APEX `ADMIN` instance account works in Administration Services. `QAFE_DEMO_BUILDER` exists in `QAFE_FORMS_DEMO`, but the browser still rejects its password after reset confirmations; the password in `.env.apex` must not be considered verified. The file remains ignored and ACL-restricted. No workspace application has been created.

On 2026-10-19, a read-only SQL*Plus check found all diagnostic accounts initially unlocked with zero failed attempts. The Builder was corrected to App Builder/SQL Workshop/Team Development = Y/N/N and remains unlocked. APEX email reset notifications are queued but undelivered because no SMTP listener exists on localhost ports 25/465/587. A **Provided** reset was confirmed by the UI, but the subsequent real browser login with the latest credential again returned `Invalid Login Credentials` and a 10-second throttle notice. A private `WWV_FLOW_FND_USER_INT.AUTHENTICATE` check returned status 1; the log records result 8. APEX defines status 1 as invalid username/password combination, status 2 as locked, 3 as change required, and 9 as delayed. The public `APEX_WORKSPACE_USER.AUTHENTICATE` call from SYS returned `ORA-06598` due to insufficient `INHERIT PRIVILEGES`; no grant was made, and that call is not a credential verdict. The diagnostic account `QAFE_DEMO_LOGIN_TEST` was used with an Oracle-generated temporary password; the private API returned status 1. It is now locked, with component flags restored to App Builder-only (Y/N/N). The Builder remains unlocked. The latest reset/login cycle does not identify whether APEX stored a different secret or input differed. Stop attempts during throttling. If continuing, reauthenticate as ADMIN and perform one final controlled ASCII-only Provided reset followed by one browser test. No password, hash, message contents, or recipients were queried. Instance parameters remain `APEX_BUILDER_AUTHENTICATION=APEX`, workspace/admin login enabled, `MAX_LOGIN_FAILURES=4`, `LOGIN_THROTTLE_DELAY=5`, and `LOGIN_THROTTLE_METHODS=USERNAME_IP`.