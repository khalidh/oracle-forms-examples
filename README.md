# Example Oracle Forms

An Oracle Forms 11g compatible set of example Oracle Forms.

## Get Started

_File: [student-db-script.sql](script/student-db-script.sql?raw=true)_

The database script for the student schema is available in `script/`. Just run the script in a tool like SQL*Plus, SQL Developer or Toad. The schema contains a simple structure to link students to courses. The script includes historical example rows; do not load those rows into production.

## Oracle APEX Migration Preview

A local, loopback-only APEX preview is available in workspace `QAFE_FORMS_CLEAN` as **QAFE Course Lookup**. Its Courses page is a read-only report for `COURSE_NO`, `DESCRIPTION` and `COST`; it currently shows the approved example courses 454–456 in ascending course-number order.

- Workspace sign-in: <http://127.0.0.1:8080/ords/qafe_clean/apex>
- Application page: <http://127.0.0.1:8080/ords/qafe_clean/r/qafe_forms_clean/qafe-course-lookup/courses>
- Environment and access notes: [docs/apex-environment.md](docs/apex-environment.md)
- Migration inventory and behavior mapping: [docs/forms-inventory.md](docs/forms-inventory.md) and [docs/migration-mapping.md](docs/migration-mapping.md)

The local database contains only the three approved COURSE rows for this preview. No student, enrollment, grade, or ZIP rows were migrated. The demo is not a production deployment or authorization decision.

## Simple Oracle Form

_File: [QAFE_FORM1.fmb](QAFE_FORM1.fmb?raw=true)_

### Features

- One window with Form Layout, having:
  - Text fields
  - Date fields
  - Number fields
- Enter query mode
- Create, Read, Update, and Delete (CRUD) functionality


## Medium Oracle Form

_File: [QAFE_FORM2.fmb](QAFE_FORM2.fmb?raw=true)_

### Features

- Three windows, having:
  - A data grid with overflow (CRUD)
    - Including LOV for zipcode
  - A data grid
  - A Master-Detail relation
- Enter query mode (only on the master of the main window and data grid)
- Create, Read, Update, and Delete (CRUD) functionality

## Complex Oracle Form

_File: [QAFE_FORM3.fmb](QAFE_FORM3.fmb?raw=true)_

### Features

- One window with Form Layout, having:
  - Text fields
  - Date fields
  - Number fields
- Validation in PL/SQL
  - Simple validation (input bigger than certain value)
  - Complex validation (check in database, if value exists)
- Post-Query using a database View Object
- Event handling with using Triggers and Program Units
- Usage of `SHOW_WINDOW` and `HIDE_WINDOW`
- Usage of `GET_ITEM_PROPERTY` and `SET_ITEM_PROPERTY`
