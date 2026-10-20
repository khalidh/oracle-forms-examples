# Implementation Plan: Migration des formulaires Oracle Forms vers Oracle APEX

**Branch**: `001-forms-apex-migration` | **Date**: 2026-10-18 | **Spec**: [spec.md](spec.md)

**Input**: Specification from `specs/001-forms-apex-migration/spec.md`

## Summary

Inventorier et exporter sans modification les trois modules Forms, confirmer leurs dependances et leurs comportements reels, puis migrer les parcours par lots vers l'APEX 24.2 deja present dans l'environnement de reference. Le schema `STUDENT` demeure la source de donnees. Le plan ne lance pas l'installation d'ORDS, l'export XML, la creation APEX ni des scripts SQL; ces actions sont des prerequis de phases ulterieures soumis a validation.

## Technical Context

**Language/Version**: Legacy SQL/PLSQL sur Oracle Database 19c; APEX 24.2.0 est enregistre VALID dans le PDB de reference. La logique APEX cible sera confirmee apres export des FMB.

**Primary Dependencies**: Oracle Database 19c; Oracle APEX 24.2; Oracle REST Data Services (ORDS) 23.3 ou plus recent pour APEX 24.2. ORDS n'a pas ete trouve dans les emplacements locaux examines.

**Storage**: Schema Oracle `STUDENT`; le script du depot est un schema d'exemple, non une preuve du schema de production.

**Testing**: Tests de non-regression par parcours, regle et operation; copies de test des donnees; controles de contraintes et de persistance. Aucun framework de test APEX existant n'a ete identifie.

**Target Platform**: Application web Oracle APEX 24.2 sur Oracle Database 19c, servie par ORDS compatible; navigateurs a confirmer avec les parties prenantes.

**Project Type**: Modernisation incrementale d'applications desktop Oracle Forms en application(s) web Oracle APEX.

**Performance Goals**: Aucune mesure de production fournie. Mesurer le temps des parcours et volumes existants pendant la decouverte; obtenir des seuils approuves avant la conception detaillee.

**Constraints**: Ne pas modifier les FMB, le schema ni les donnees legacy pendant l'analyse. Ne pas generer/importer d'application APEX dans cette phase. Refuser par defaut les operations ciblees jusqu'a approbation de la matrice d'autorisations. Confirmer ORDS, XML DB, memoire et configuration avant un environnement APEX deployable.

**Scale/Scope**: Trois modules `QAFE_FORM1/2/3` et les 11 tables, 7 vues, 5 sequences, 5 types et packages visibles dans `script/student-db-script.sql`. Volumes de production et dependances externes inconnus.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

La constitution `.specify/memory/constitution.md` est encore le template Spec Kit avec placeholders; elle ne constitue pas des principes ratifies et ne permet pas d'inventer des gates.

Gates tires des exigences approuvees de la specification:

| Gate | Resultat | Preuve / condition |
|---|---|---|
| Analyse en lecture seule des sources legacy | PASS | Les exports Forms sont des artefacts derives; les FMB, donnees et objets ne sont pas modifies. |
| Pas de code ni import APEX dans cette phase | PASS | Les livrables sont des documents de recherche et de conception seulement. |
| Provenance avant equivalence | PASS avec prerequis | Les binaires n'ont pas encore ete exportes; aucun composant interne n'est presume. |
| Securite par defaut refusee | PASS avec gate | Aucune operation metier ciblee avant une matrice d'autorisations approuvee. |
| Compatibilite cible | PASS pour la baseline, deployment gate ouvert | APEX 24.2.0 est present et Oracle 19c est en 19.3; APEX 24.2 requiert Oracle 19c ou plus recent et ORDS 23.3+. ORDS reste a installer/configurer avant un test web de deploiement. |

Aucune violation de principe ratifie n'est constatee. L'approbation des owners, les exports XML et la disponibilite ORDS restent des gates avant l'implementation.

## Project Structure

### Documentation (this feature)

```text
specs/001-forms-apex-migration/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- checklists/requirements.md
`-- tasks.md             # future output of /speckit-tasks
```

### Legacy Sources (read-only during planning)

```text
QAFE_FORM1.fmb
QAFE_FORM2.fmb
QAFE_FORM3.fmb
script/student-db-script.sql
specs/001-forms-apex-migration/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- checklists/requirements.md
`-- docs/             # livrables d'analyse ulterieure requis par la spec
```

**Structure Decision**: Le depot legacy reste intact. Cette feature ne produit que des documents versionnables sous `specs/001-forms-apex-migration/`; les livrables `docs/*` de la specification seront crees apres export/analyse. Aucun contrat externe n'est emis tant qu'une interface externe n'est pas identifiee.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | Aucun choix de complexite supplementaire n'est engage dans cette phase. | N/A |
