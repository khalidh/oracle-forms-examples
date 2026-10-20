# Acceptance Evidence

Store one Markdown record per user story or accepted migration slice. Tests must use an isolated, approved environment and must not write to the legacy database.

## Required Record Fields

- Story, test ID, and linked source ID
- Preconditions and sanitized fixture identifiers
- User action and relevant role
- Expected screen/message and expected persisted state
- Actual result, pass/fail, date, and reviewer
- Legacy proof status: documented, observed, inferred, or unverified
- Defect/reference for any discrepancy

Do not mark an unexported Forms behavior as covered. Keep credentials, production data, and secrets out of this directory.