# Security Matrix

## Interim Gate

The owner selected a default-deny policy. Until the Forms access model is inventoried and an APEX authorization matrix is approved, all business operations are disabled. Do not infer user identities, roles, or data visibility from the example schema.

## Authorization Register

| Actor / role | Read scope | Create | Update | Delete | Sensitive data | Source / approval |
|---|---|---|---|---|---|---|
| Unknown | Unknown | Denied by default | Denied by default | Denied by default | Unknown | Forms XML has no matches for the searched role/security/privilege property names; deployment/database controls and owner approval remain unverified |
| Authenticated user of the local demo workspace only | COURSE: `COURSE_NO`, `DESCRIPTION`, `COST`; local example data only | Denied | Denied | Denied | Example course data; not production | Owner approved 2026-10-19 for a loopback-only demo in `ORACLE_FORMS_EXAMPLES`; not a production authorization decision |
| Authenticated user of `QAFE_FORMS_CLEAN` | `QAFE_CLEAN.STUDENT.COURSE`: `COURSE_NO`, `DESCRIPTION`, `COST`; rows 454, 455, and 456 only | Denied | Denied | Denied | Local example course data; not production | Owner approved clean PDB/workspace on 2026-10-20; local preview remains loopback-only |
| `QAFE_FORMS_BUILDER` in `QAFE_FORMS_CLEAN` | Form 2 local fields: INSTRUCTOR, STUDENT, COURSE, SECTION, ZIPCODE | INSTRUCTOR/STUDENT: allowed locally | INSTRUCTOR/STUDENT: allowed locally | INSTRUCTOR/STUDENT: allowed locally | Includes instructor/student personal data; synthetic/local only | Owner authorized 2026-10-20 for `QAFE_CLEAN`; COURSE/SECTION remain read-only per Forms DML flags; no legacy/production access |

The Forms2XML review found no matching role/security/privilege attributes in the exported modules. This targeted search does not prove that external authentication, database grants, menu restrictions, or deployment-level controls are absent.

Populate this matrix only from verified Forms evidence and a named owner decision. Validate access server-side; hidden or disabled controls are not authorization. Keep credentials and secrets out of this file.

Both local scopes are limited to the local workspaces and loopback-only access on `127.0.0.1`. Form 1 remains limited to its three listed COURSE columns with no writes. Form 2 access is limited to the approved Builder in `QAFE_CLEAN`; Form 2 writes are only for INSTRUCTOR/STUDENT. No scope authorizes network exposure or production deployment.

On 2026-10-20 the owner authorized a one-time Form 1 CRUD fixture test by `QAFE_FORMS_BUILDER`; it was deleted and page 6 disabled. The owner subsequently authorized local Form 2 access and ongoing CRUD for INSTRUCTOR/STUDENT in `QAFE_CLEAN`. Implement only behind server-side Builder authorization; never use legacy or production data.