# APEX Migration Artifacts

No APEX application export is created during discovery. Store a reviewed application export here only after the target workspace, security model, and implementation scope are approved.

Do not commit credentials, workspace exports containing secrets, production data, or unreviewed imports. The expected application export path is `apex/QAFE_MIGRATION.sql`; it is not present yet.

## Local APEX Administration

The local `ADMIN` instance account was reset in the `ORACLE_FORMS_EXAMPLES` PDB with the APEX 24.2 `apxchpwd.sql` script. The script generated a random password and stored local connection details in repository-root `.env.apex`; that file is ignored by Git and ACL-restricted. Never print it, commit it, or copy its password into chat. The checked-in `.env.apex.example` contains names and URLs only.

The local demo workspace `QAFE_FORMS_DEMO` is provisioned against the existing `STUDENT` schema. Its `QAFE_DEMO_BUILDER` account is intended for App Builder only, with SQL Workshop and Team Development disabled. A read-only check on 2026-10-19 found its Team Development flag enabled, contrary to that intent; the reset helper does not reapply the SQL Workshop or Team Development flags. Its password is stored only in `.env.apex` and remains unverified. No APEX application has been created yet.

For a workspace sign-in, use `QAFE_FORMS_DEMO` / `QAFE_DEMO_BUILDER` at `http://127.0.0.1:8080/ords/forms_examples/apex`. A second account, `QAFE_DEMO_LOGIN_TEST`, was created to isolate authentication. A temporary full developer/admin profile did not change its APEX auth result and has been reverted. Both accounts are unlocked with zero failed attempts, but the local APEX authentication API rejects them. A separate `QAFE_DEMO_SCRIPT_ADMIN` account exists with SQL Workshop and Team Development enabled; do not use it for the demo, and do not infer successful authentication from its presence. A shared `.env.apex.pending` file exists; its contents and originating script have not been inspected. Stop password rotations and investigate instance/workspace authentication. Keep all APEX passwords out of chat and Git.

To intentionally rotate the local administrator password again, run `scripts/reset_apex_admin.ps1 -RotateExisting`. The script requires local SQL*Plus OS authentication as SYS and targets only `ORACLE_FORMS_EXAMPLES`; it refuses to overwrite credentials unless rotation is explicit. Administration Services is available at `http://127.0.0.1:8080/ords/forms_examples/apex_admin` while local ORDS is running.