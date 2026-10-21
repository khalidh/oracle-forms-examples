# Test Fixtures

Only sanitized, owner-approved fixtures may be used for migration tests. Do not copy production data or connect write tests to the legacy source schema.

Before creating fixtures, document the source tables, generated identifiers, relationships, and reset procedure. Keep fixture data separate from database migration scripts and verify that each test can clean up or restore its isolated state.

## Owner-Approved Preview Data Exception

On 2026-10-21, the owner explicitly approved a one-time read-only copy from `ORACLE_FORMS_EXAMPLES` into the isolated `QAFE_CLEAN` preview: 257 `STUDENT`, 10 `INSTRUCTOR`, their 146 referenced `ZIPCODE` rows, and all 62 `SECTION` rows. The copy preserved source columns and audit values; the source PDB was not modified. Fifty-two SECTION rows reference COURSE numbers absent from the three-row target preview; no other COURSE rows were copied. This exception is for the authenticated Builder and loopback preview only. It does not authorize further historical-data copies, production use, network exposure, or writes to the source PDB. Remove the copied records if the owner retires this local preview.