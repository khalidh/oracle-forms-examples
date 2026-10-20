# Forms XML Exports

This directory contains derived Forms2XML output only. Do not place source `.fmb` files here or overwrite the repository originals.

## Export Procedure

Use Oracle Forms2XML from the installed Oracle Home after reviewing the utility syntax. In the verification run, this launcher wrote the XML beside the input `.fmb` despite changing the PowerShell working directory. Move each newly generated XML into this directory only after confirming the destination does not exist.

```powershell
$env:ORACLE_HOME = 'C:\Oracle\Middleware\Oracle_Home'
& "$env:ORACLE_HOME\forms\templates\scripts\frmf2xml.bat" `
  'C:\Users\Administrator\Documents\vs-projects\oracle-forms-forms-from-github\oracle-forms-examples\QAFE_FORM1.fmb' `
  'USE_PROPERTY_IDS=YES' 'OVERWRITE=NO' 'DUMP=ALL'
```

Repeat for `QAFE_FORM2.fmb` and `QAFE_FORM3.fmb`. Confirm the expected `<module>_fmb.xml` exists beside the source, then move it to `docs/forms-exports/` without overwriting. Never use `OVERWRITE=YES` without reviewing the existing export and approval.

## Evidence Register

| Source module | Export file | SHA-256 | Forms2XML version | Exported at | Review status |
|---|---|---|---|---|---|
| `QAFE_FORM1.fmb` | `QAFE_FORM1_fmb.xml` | `440936BBCE47DC3958E20A5F963768B23B855A9767983B73C2815C7A5E4CB045` | 14.1.2 | 2026-10-18 | Parsed; inventory recorded |
| `QAFE_FORM2.fmb` | `QAFE_FORM2_fmb.xml` | `EC86B66ABBBD3A61A2A37DC4F5B2D03436E4F9D225C37DD564E96BEA62487B69` | 14.1.2 | 2026-10-18 | Parsed; inventory recorded |
| `QAFE_FORM3.fmb` | `QAFE_FORM3_fmb.xml` | `512216A7B0F8079DCFDD572F234CA9554E01EF1FFF148B71A3CECC40F96BE5AA` | 14.1.2 | 2026-10-18 | Parsed; inventory recorded |

Record source and export hashes, tool version, options, warnings, and reviewer. Treat the XML as evidence, not as a replacement for the original module.

Source FMB hashes were verified unchanged after export: Form 1 `4C9EBAC6E730FBD502A65CE2A58EC33287E4B604929979F18D69E610BFBBF3D6`; Form 2 `43DB95278C9D996DE602A1D0533609B7115FF502D585D6642595834224D3CDCA`; Form 3 `2CD4FF34498036B2ED10564677394ECABA583CCB5BB31CA2CE0A8BBBF2AF4120`. The `DUMP=ALL` converter warning states that these XML files cannot be converted back to FMB; this is expected for the full analysis dump.