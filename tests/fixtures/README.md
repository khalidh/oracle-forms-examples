# Test Fixtures

Only sanitized, owner-approved fixtures may be used for migration tests. Do not copy production data or connect write tests to the legacy source schema.

Before creating fixtures, document the source tables, generated identifiers, relationships, and reset procedure. Keep fixture data separate from database migration scripts and verify that each test can clean up or restore its isolated state.