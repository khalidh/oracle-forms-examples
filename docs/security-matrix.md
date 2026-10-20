# Security Matrix

## Interim Gate

The owner selected a default-deny policy. Until the Forms access model is inventoried and an APEX authorization matrix is approved, all business operations are disabled. Do not infer user identities, roles, or data visibility from the example schema.

## Authorization Register

| Actor / role | Read scope | Create | Update | Delete | Sensitive data | Source / approval |
|---|---|---|---|---|---|---|
| Unknown | Unknown | Denied by default | Denied by default | Denied by default | Unknown | Forms XML has no matches for the searched role/security/privilege property names; deployment/database controls and owner approval remain unverified |
| Authenticated user of the local demo workspace only | COURSE: `COURSE_NO`, `DESCRIPTION`, `COST`; local example data only | Denied | Denied | Denied | Example course data; not production | Owner approved 2026-10-19 for a loopback-only demo in `ORACLE_FORMS_EXAMPLES`; not a production authorization decision |

The Forms2XML review found no matching role/security/privilege attributes in the exported modules. This targeted search does not prove that external authentication, database grants, menu restrictions, or deployment-level controls are absent.

Populate this matrix only from verified Forms evidence and a named owner decision. Validate access server-side; hidden or disabled controls are not authorization. Keep credentials and secrets out of this file.

The local demo approval is limited to the local APEX workspace served only on `127.0.0.1`. It does not authorize exposing the other four COURSE columns, writes, network access, or production deployment.