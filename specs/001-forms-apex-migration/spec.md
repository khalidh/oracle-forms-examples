# Feature Specification: Migration des formulaires Oracle Forms vers Oracle APEX

**Feature Branch**: _Aucune branche creee (aucun hook de branche configure)_

**Created**: 2026-10-18

**Status**: Draft — decisions de cadrage et export des sources binaires requis

**Input**: User description: analyser les trois formulaires Oracle Forms de ce depot et produire une specification fonctionnelle, verifiable et traceable pour leur modernisation vers Oracle APEX, sans implementer ni importer d'application APEX.

**Priorisation**: Les priorites P1/P2 ci-dessous sont une proposition de sequence fondee sur les dependances et les preuves disponibles; elles ne representent pas une priorite metier validee par les utilisateurs.

## Clarifications

### Session 2026-10-18

- Q: Quelles versions d'Oracle Database et d'APEX veux-tu cibler ? → A: Oracle Database 19c; le schema STUDENT reste la source de reference; choisir une release APEX compatible avec 19c et confirmer son numero exact pendant la planification.
- Q: Dois-tu preserver le CRUD annonce par le README, meme si les triggers SQL fournis ne font rien lors des mises a jour et suppressions ? → A: Preserver le CRUD annonce; les branches UPDATE/DELETE sans effet sont une anomalie a confirmer avec le proprietaire et a corriger avant l'implementation si le comportement est approuve.
- Q: Quelles identites et autorisations veux-tu appliquer dans APEX pour chaque operation ? → A: Reporter la definition des roles apres l'inventaire; refuser par defaut l'acces aux operations metier jusqu'a l'approbation d'une matrice d'autorisations.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Etablir une base de migration verifiable (Priority: P1)

En tant que responsable de migration, je veux disposer d'un inventaire trace des formulaires, objets et regles legacy afin de planifier la modernisation sans perdre de comportement ni confondre faits et hypotheses.

**Why this priority**: Les fichiers Forms sont binaires et les documents disponibles ne decrivent pas leurs composants internes. L'export et la provenance sont des prealables a toute equivalence fonctionnelle.

**Independent Test**: Un relecteur peut retrouver chaque affirmation de l'inventaire dans un fichier source, un export Forms ou une observation explicitement etiquetee; tout element non exporte est marque inconnu.

**Acceptance Scenarios**:

1. **Given** le depot contenant `QAFE_FORM1.fmb`, `QAFE_FORM2.fmb`, `QAFE_FORM3.fmb`, `README.md` et `script/student-db-script.sql`, **When** l'inventaire est prepare, **Then** les trois modules sont identifies et chaque constat est classe comme observe, documente, infere ou a confirmer.
2. **Given** aucun export XML des modules n'est fourni, **When** un composant interne est recherche, **Then** son nom ou son comportement n'est pas invente et le format d'export et l'outil Oracle requis sont consignes.
3. **Given** une vue, un trigger ou un traitement SQL est cite, **When** le lecteur suit la reference de provenance, **Then** il peut identifier le fichier et l'objet SQL correspondant.

### User Story 2 - Consulter et rechercher les donnees metier (Priority: P1)

En tant qu'utilisateur autorise du systeme de gestion des cours, je veux consulter et rechercher les donnees exposees par les formulaires afin de retrouver les cours, sections, etudiants ou instructeurs necessaires a mon travail.

**Why this priority**: Le README documente le mode requete et les formulaires de consultation; les parcours exacts et les criteres de recherche restent a confirmer par export des modules.

**Independent Test**: Pour chaque parcours confirme, un jeu de donnees de reference permet de lancer la recherche, parcourir les resultats et comparer les donnees affichees au comportement Forms approuve.

**Acceptance Scenarios**:

1. **Given** un utilisateur autorise et des donnees correspondant a ses criteres, **When** il lance une recherche, **Then** seuls les enregistrements correspondants sont presentes avec les relations et valeurs documentees.
2. **Given** qu'aucun enregistrement ne correspond, **When** la recherche est terminee, **Then** l'utilisateur recoit un resultat vide explicite sans afficher de donnees hors critere.
3. **Given** plusieurs resultats, **When** l'utilisateur parcourt les lignes ou passe a la page suivante, **Then** aucun enregistrement n'est perdu, duplique ou modifie par la navigation.

**Sources**: `README.md` documente le mode requete de Form 1 et Form 2; le mapping des blocs, items et criteres effectifs demeure a confirmer a partir des exports `.fmb`.

### User Story 3 - Creer et maintenir les donnees (Priority: P1)

En tant qu'utilisateur autorise, je veux creer, modifier et supprimer les enregistrements metier permis afin de maintenir les informations de cours et de gestion des etudiants.

**Why this priority**: Le README annonce des operations CRUD pour les trois exemples, mais le script SQL contient des triggers de vues dont les branches UPDATE et DELETE sont des no-op. L'intention fonctionnelle ne peut donc pas etre deduite de cette seule source.

**Independent Test**: Chaque operation autorisee est verifiee par un scenario de bout en bout et par comparaison de l'etat persiste avant/apres; une operation refusee ne doit pas annoncer un succes ni laisser de modification partielle.

**Acceptance Scenarios**:

1. **Given** un utilisateur autorise et une nouvelle donnee valide, **When** il l'enregistre, **Then** elle est persistante et reconsultable avec ses valeurs attendues.
2. **Given** un enregistrement existant et une modification valide, **When** l'utilisateur confirme la modification, **Then** la nouvelle valeur est persistante et les autres enregistrements restent inchanges.
3. **Given** un enregistrement existant et une suppression autorisee, **When** l'utilisateur confirme la suppression, **Then** la suppression ou son refus motive correspond a la regle approuvee et l'etat persistant est verifiable.
4. **Given** le comportement contradictoire entre le README et les triggers `V_QAFE_FORM1_COURSE_TRG`, `V_QAFE_FORM2_INSTRUCTOR_TRG` et `V_QAFE_FORM2_STUDENT_TRG`, **When** la politique de migration est arretee, **Then** chaque branche INSERT/UPDATE/DELETE est classee comme comportement a conserver ou anomalie a corriger avant le plan.

**Sources**: `README.md`; objets et triggers SQL nommes dans la section Evidence. Les comportements des items et boutons des FMB ne sont pas encore extraits.

### User Story 4 - Appliquer les validations et comprendre les erreurs (Priority: P1)

En tant qu'utilisateur autorise, je veux recevoir les validations et messages appropries afin de corriger les donnees invalides sans perdre mon travail.

**Why this priority**: Le script SQL contient des validations observables sur `STUDENT.FIRST_NAME` et le code postal; les autres validations Forms ne peuvent etre certifiees sans export.

**Independent Test**: Des cas valides, invalides, limites et dependants d'une reference sont executes; les donnees rejetees ne sont pas persistees et le message observable correspond a la regle approuvee.

**Acceptance Scenarios**:

1. **Given** un etudiant dont `FIRST_NAME` est vide, **When** il est insere ou modifie, **Then** l'enregistrement est refuse avec le message de validation approuve et sans changement partiel.
2. **Given** un code postal present dans `ZIPCODE`, **When** l'utilisateur le saisit, **Then** le comportement de validation et l'affichage de ville/etat reproduisent la regle confirme dans les sources exportees.
3. **Given** un code postal absent, **When** l'utilisateur valide le champ, **Then** le traitement indique que le code postal n'existe pas et ne persiste pas une valeur invalide.

**Sources**: `TRIGGER_STUDENT_BEFORE_INSERT`, `TRIGGER_STUDENT_BEFORE_UPDATE`, `ADF_EX10_01_TRIGGERS.STUDENT_POSTQ` et `ADF_EX10_01_TRIGGERS.STUDENT_ZIP_WVI` dans `script/student-db-script.sql`. Le rattachement exact de ces objets aux formulaires doit etre confirme par export.

### User Story 5 - Exploiter les vues en grille et les relations (Priority: P2)

En tant qu'utilisateur autorise, je veux naviguer entre les donnees liees et choisir une valeur de code postal dans les parcours documentes afin de maintenir les informations sans ressaisie incoherente.

**Why this priority**: Le README de Form 2 documente plusieurs grilles, une relation maitre-detail et une LOV de code postal; les cardinalites, actions et regles exactes ne sont pas visibles dans les binaires.

**Independent Test**: Pour chaque relation et LOV confirmee, un jeu de test verifie l'ouverture, la selection, l'annulation, l'absence de resultat et la coherence de l'enregistrement parent/enfant.

**Acceptance Scenarios**:

1. **Given** un enregistrement maitre avec des donnees detail liees, **When** l'utilisateur selectionne le maitre, **Then** seules les donnees detail correspondantes sont affichees.
2. **Given** une LOV de code postal confirmee, **When** l'utilisateur choisit une valeur ou annule la selection, **Then** la valeur et les champs derives suivent le comportement approuve sans ecrasement non sollicite.
3. **Given** qu'un utilisateur n'a pas acces a une operation ou une donnee, **When** il tente l'action, **Then** l'acces est refuse cote serveur et aucune modification n'est persistante.

**Sources**: description de `QAFE_FORM2.fmb` dans `README.md`; les objets `V_QAFE_FORM2_*` et les contraintes disponibles dans le script SQL; composants internes a confirmer par export.

### User Story 6 - Valider une migration incrementale (Priority: P2)

En tant que proprietaire du systeme, je veux migrer les parcours par perimetre fonctionnel et verifier leur couverture avant de retirer Forms afin de limiter le risque et de pouvoir accepter ou reporter chaque lot.

**Why this priority**: Le depot regroupe trois formulaires et des objets partages; les dependances entre modules et les priorites metier ne sont pas etablies.

**Independent Test**: Un lot n'est considere candidat a l'acceptation que si ses exigences, sources, tests de non-regression, ecarts connus et validations de securite sont relies dans la matrice de tracabilite.

**Acceptance Scenarios**:

1. **Given** un perimetre de formulaire approuve, **When** un lot de migration est prepare, **Then** ses sources et dependances partagees sont explicites et les autres formulaires restent hors du lot.
2. **Given** un test legacy ou une source manquante, **When** la couverture est rapportee, **Then** l'element est marque non analyse ou bloque et n'est jamais declare couvert par inference.
3. **Given** un lot dont les tests sont termines, **When** le proprietaire examine les resultats, **Then** les ecarts, risques et decisions d'acceptation sont explicites avant toute mise hors service du parcours Forms.

### Edge Cases

- Un `.fmb` ne peut pas etre inspecte comme du texte et aucun export XML n'est fourni; les noms de blocs, items, LOV, relations, triggers Forms, program units, menus et appels externes restent inconnus.
- La documentation annonce CRUD alors que plusieurs triggers `INSTEAD OF` contiennent `WHERE 1 = 0` pour UPDATE/DELETE; une interface pourrait afficher une action sans persistance reelle.
- `V_EX01_01_STUDENT` reference `STUDENT_TEST`, dont la creation n'apparait pas parmi les tables du script; sa dependance et son usage doivent etre verifies.
- `V_EX10_01_STUDENT` expose `CITY`, `STATE` et `EXIT` comme colonnes calculees a `NULL`; des INSERT du script ciblent ces colonnes et ont provoque `ORA-01733` lors du chargement local.
- Un code postal peut etre absent, mal forme ou supprime entre selection et validation; le comportement de concurrence et les messages doivent etre testes.
- Une modification peut violer une cle primaire, une cle etrangere ou une contrainte unique, ou rencontrer une suppression parent avec enfants.
- Un utilisateur peut perdre la connexion au milieu d'une transaction; le resultat doit etre tout-ou-rien et verifiable.
- Les dimensions de canvas et controles depassant du canvas sont a examiner: `QAFE_FORM2.err` contient des avertissements `FRM-32093` pour plusieurs items d'instructeur lors de la compilation locale.
- Les volumes de l'exemple local ne constituent pas une mesure de production; performance, pagination, concurrence et taille de BLOB `PS_TXN.CONTENT` sont inconnues.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'equipe MUST inventorier les trois modules sources `QAFE_FORM1.fmb`, `QAFE_FORM2.fmb` et `QAFE_FORM3.fmb`, le README, le script SQL, les sorties generees et toute dependance effectivement fournie; chaque entree MUST porter un statut de preuve.
- **FR-002**: Avant de figer l'inventaire des composants Forms, l'equipe MUST obtenir pour chaque FMB un export XML lisible ou une extraction equivalente approuvee par Oracle Forms Builder/Forms2XML; les composants non extraits MUST rester explicitement non analyses.
- **FR-003**: La specification MUST separer les parcours presentes par le README, les observations d'execution, les faits SQL et les comportements encore non confirmes; toute affirmation MUST referencer son fichier et son objet ou son export.
- **FR-004**: Pour chaque parcours de recherche/consultation confirme, le comportement cible MUST definir les criteres, resultats, ordre, navigation, etats vides, erreurs et permissions a tester.
- **FR-005**: Pour chaque operation de creation, modification ou suppression exposee par les sources, le comportement cible MUST preciser si elle reussit, echoue ou est interdite; son resultat persistant MUST etre verifie par un test.
- **FR-006**: La migration MUST fournir le CRUD annonce dans le README pour les parcours confirmes par le proprietaire; les branches UPDATE/DELETE `WHERE 1 = 0` des triggers de vues MUST etre traitees comme une anomalie du script a confirmer et ne MUST pas etre reprises comme comportement cible sans effet. Toute operation annoncee comme reussie MUST produire un resultat persistant verifiable.
- **FR-007**: Chaque regle metier identifiee MUST documenter un identifiant, source exacte, conditions, entrees, effets, messages et cas limites; les statuts observe/documente/infere/a confirmer MUST rester distincts.
- **FR-008**: Les validations connues sur `FIRST_NAME` et `ZIP`, ainsi que les traitements POST-QUERY associes, MUST faire l'objet de tests positifs, negatifs et de persistance; les autres validations MUST attendre l'export des FMB.
- **FR-009**: Le modele de donnees MUST inventorier les 11 tables et 7 vues du script, leurs colonnes, cles, contraintes, sequences, types et packages; les relations sans contrainte declaree MUST etre distinguees des cles etrangeres effectivement declarees.
- **FR-010**: Le comportement cible MUST couvrir les grilles, relations maitre-detail, LOV et actions personnalisees uniquement lorsqu'elles sont confirmees par les sources; les choix de composants APEX MUST rester des options de conception, pas des equivalences presumees.
- **FR-011**: Jusqu'a l'inventaire des sources et l'approbation d'une matrice d'autorisations par le proprietaire, les operations metier MUST etre refusees par defaut. La cible MUST definir les identites, roles, autorisations par operation et donnees protegees; les controles d'acces et validations sensibles MUST etre verifies cote serveur et suivre le moindre privilege.
- **FR-012**: La migration MUST cibler Oracle Database 19c et une release APEX compatible avec cette version; la release APEX exacte MUST etre selectionnee et verifiee contre les exigences de compatibilite Oracle pendant la planification, avant implementation.
- **FR-013**: La non-regression MUST relier chaque comportement confirme a au moins un test avec preconditions, action, resultat attendu, source legacy et statut de preuve; les cas nominaux, limites, erreurs, permissions et concurrence pertinente MUST etre couverts.
- **FR-014**: La migration MUST etre planifiee en lots incrementaux par formulaire ou parcours, en rendant explicites les dependances partagees, sans attribuer de priorite metier non validee.
- **FR-015**: Avant le plan d'implementation, l'equipe MUST produire les livrables distincts `docs/forms-inventory.md`, `docs/trigger-analysis.md`, `docs/data-model.md`, `docs/migration-mapping.md`, `docs/traceability-matrix.md` et `docs/migration-risks.md`; cette phase `/speckit-specify` ne cree que `spec.md` et sa checklist.
- **FR-016**: Le comportement cible MUST expliciter les differences desktop/web, les exigences d'accessibilite, les navigateurs, la responsivite, les seuils de performance, les volumes, le deploiement, la sauvegarde, le retour arriere, l'audit et la journalisation avant approbation du plan.
- **FR-017**: L'analyse et la specification MUST rester en lecture seule vis-a-vis des FMB, des donnees et des objets legacy; aucune conversion destructive, modification de schema, generation/import APEX ou equivalence non testee n'est autorisee dans cette phase.

### Evidence Baseline and Proof Limits

Les etiquettes suivantes s'appliquent dans cette specification: **DOCUMENTE** = README; **OBSERVE** = source texte ou execution locale; **A CONFIRMER** = assertion dont la preuve complete necessite un export ou une decision du proprietaire.

| Source | Preuve disponible | Constat utilisable | Limite |
|---|---|---|---|
| `README.md` | DOCUMENTE | Form 1: formulaire simple, mode requete et CRUD. Form 2: trois fenetres, grilles, LOV ZIP, maitre-detail, mode requete et CRUD. Form 3: formulaire, validations PL/SQL, POST-QUERY, triggers/program units, SHOW/HIDE_WINDOW et proprietes d'items. | Ces descriptions ne remplacent pas l'inventaire des modules. |
| `QAFE_FORM1.fmb`, `QAFE_FORM2.fmb`, `QAFE_FORM3.fmb` | OBSERVE: fichiers binaires presents | Trois modules sources sont fournis. | Aucun export XML/FMT ni inventaire de composants internes n'est present. Les blocs, items, canvas, LOV, triggers Forms, menus et appels externes restent A CONFIRMER. |
| `script/student-db-script.sql` | OBSERVE: DDL/DML texte | 11 tables: COURSE, ENROLLMENT, GRADE, GRADE_CONVERSION, GRADE_TYPE, GRADE_TYPE_WEIGHT, INSTRUCTOR, PS_TXN, SECTION, STUDENT, ZIPCODE; 7 vues `V_*`; 5 sequences; 5 types objet/collection; packages `ADF_EX10_01_TRIGGERS`, `STUDENTPKG` et corps associes. | Le script est un dump d'exemple; son exhaustivite, ses objets de production et sa coherence complete ne sont pas etablis. |
| Triggers et packages du script SQL | OBSERVE: texte SQL | `TRIGGER_STUDENT_BEFORE_INSERT/UPDATE` rejettent `FIRST_NAME` nul avec erreur -20101. `STUDENT_POSTQ` lit ville/etat depuis ZIPCODE. `STUDENT_ZIP_WVI` renseigne un message si le ZIP n'existe pas. | Le rattachement exact aux modules et le comportement UI correspondant sont A CONFIRMER. |
| Triggers de vues du script SQL | OBSERVE: texte SQL | Les triggers de `V_QAFE_FORM1_COURSE`, `V_QAFE_FORM2_INSTRUCTOR` et `V_QAFE_FORM2_STUDENT` ont INSERT vers table de base; UPDATE/DELETE utilisent `WHERE 1 = 0`. | Conflit avec le CRUD documente; intention metier non connue. |
| `V_EX01_01_STUDENT` et `V_EX10_01_STUDENT` | OBSERVE: texte SQL | La premiere reference `STUDENT_TEST`; la seconde expose CITY/STATE/EXIT sous forme de `NULL`. Les INSERT de ces colonnes dans le dump ont provoque ORA-01733 lors du chargement local. | Dependances et usage par Form 3 a confirmer; ne pas attribuer ces vues a un formulaire sans export. |
| `QAFE_FORM2.err` et `QAFE_FORM*.fmx` | OBSERVE: sorties locales generees | Des FMX sont presents; le rapport local Form 2 signale FRM-32093 sur des items d'instructeur. | Sorties generees, non sources d'autorite; les avertissements ne prouvent pas seuls le comportement utilisateur final. |
| Fichiers non trouves dans le depot source | OBSERVE: inventaire du depot | Aucun `.fmt`, export XML, `.pll`, `.plx`, `.mmb`, `.mmx`, `.olb`, capture ou configuration de deploiement source n'est fourni. | Les dependances externes peuvent exister hors de ce depot. |

Outil d'extraction a utiliser: produire un export Oracle Forms XML de chaque FMB avec Oracle Forms Builder (commande de conversion/export XML) ou l'utilitaire Oracle Forms2XML/`frmf2xml`. Aucun `frmf2xml` autonome n'a ete trouve dans `Oracle_Home\bin` pendant l'inventaire; la commande disponible dans le Builder devra etre validee avec la version installee. Les `.fmb` ne sont pas convertis dans cette phase.

### Key Entities *(include if feature involves data)*

- **Course**: cours avec numero, description, cout, prerequis et champs de creation/modification; le script declare une cle primaire sur COURSE_NO et une auto-reference de PREREQUISITE a COURSE_NO.
- **Section**: occurrence de cours avec SECTION_NO, COURSE_NO, dates, lieu, instructeur et capacite; le script declare une unicite sur (SECTION_NO, COURSE_NO). Les liens COURSE_NO/INSTRUCTOR_ID ne sont pas declares comme cles etrangeres dans ce script.
- **Instructor**: profil avec identifiant, nom, adresse, ZIP, telephone et audit; ZIP references ZIPCODE.
- **Student**: profil avec identifiant, nom, adresse, ZIP, telephone, employeur, inscription et audit; ZIP references ZIPCODE.
- **Enrollment**: association STUDENT_ID/SECTION_ID avec date d'inscription et note finale; cle primaire composite declaree. Le script ne declare pas de FK vers STUDENT ou SECTION.
- **Grade**: note par etudiant, section et type; references ENROLLMENT(STUDENT_ID, SECTION_ID) et GRADE_TYPE_WEIGHT(SECTION_ID, GRADE_TYPE_CODE).
- **Grade type et poids**: tables de reference/calcul du poids de notes; GRADE_TYPE_WEIGHT declare une cle composite SECTION_ID/GRADE_TYPE_CODE.
- **Grade conversion**: conversion entre note lettre et points/plage numerique.
- **Zipcode**: code postal, ville, etat et audit; referencee par STUDENT et INSTRUCTOR.
- **PS_TXN**: donnees BLOB avec identifiants parent/collection; usage metier et necessite de migration A CONFIRMER.

### Migration Deliverables Required Before Planning

Les documents ci-dessous sont des livrables des phases d'analyse suivantes; ils ne sont pas generes par cette commande de specification:

1. `docs/forms-inventory.md`: inventaire verifie par export des modules et dependances.
2. `docs/trigger-analysis.md`: chaque trigger, regle, effet de bord et decision de mapping.
3. `docs/data-model.md`: tables, vues, colonnes, cles, relations et objets SQL, avec statut de preuve.
4. `docs/migration-mapping.md`: parcours Forms observes et comportement cible APEX non prescriptif.
5. `docs/traceability-matrix.md`: ID source → regle → exigence/US → comportement cible → test → preuve.
6. `docs/migration-risks.md`: lacunes, risques, arbitrages, dependances et plans d'attente.

### Blocking Decisions

- **Platform target (resolved)**: Oracle Database 19c; le schema STUDENT reste la source de reference; une release APEX compatible avec 19c sera selectionnee et confirmee pendant la planification.
- **CRUD discrepancy (resolved)**: Preserver le CRUD annonce par le README; faire confirmer et corriger les branches UPDATE/DELETE sans effet avant implementation.
- **Security model (resolved)**: Definir les roles et autorisations apres l'inventaire; refuser par defaut l'acces aux operations metier jusqu'a approbation de la matrice.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des modules inclus disposent d'un inventaire de composants soit rattache a un export source, soit explicitement marque non analyse; aucune affirmation sur un composant sans preuve n'est presentee comme un fait.
- **SC-002**: 100% des parcours, regles et operations confirmees possedent au moins un scenario d'acceptation et une reference de provenance avant approbation du plan.
- **SC-003**: 100% des operations CRUD retenues et regles de validation passent leurs tests nominaux, limites, erreurs et permissions avant acceptation de leur lot.
- **SC-004**: Les decisions de versions, de donnees et de securite sont approuvees et associees a une preuve avant le gel du plan de migration.
- **SC-005**: Les volumes et temps de reference sont mesures sur un jeu de donnees representatif; les seuils cibles sont approuves avant recette, sans supposer que les 2 142 lignes de l'exemple local representent la production.
- **SC-006**: Aucun schema, objet, enregistrement ou module Forms n'est modifie par la phase de specification; toute equivalence fonctionnelle est soutenue par des tests approuves.

## Assumptions

- Le perimetre initial comprend les trois modules `QAFE_FORM1`, `QAFE_FORM2` et `QAFE_FORM3`, ainsi que les objets SQL et la documentation presents dans ce depot; les dependances externes ne sont pas presumees absentes.
- Le README est une source de parcours documentes, pas une preuve que les comportements sont fonctionnels ou actuels.
- Le SQL `STUDENT` est un schema d'exemple; le total local charge auparavant n'est pas un volume de production ni une cible de capacite.
- La priorite des lots sera proposee selon les dependances observees puis validee par le proprietaire metier; elle n'est pas deduite de l'ordre des fichiers.
- Le fichier `.specify/memory/constitution.md` contient encore les placeholders du template Spec Kit et ne fournit pas de principes projet ratifies.
- Les exports binaires, profils/roles reels, transactions/commits Forms, fenetres, menus, appels inter-formulaires, erreurs fonctionnelles et seuils de performance doivent etre fournis ou confirmes avant que la couverture puisse etre declaree complete.
- Aucune application APEX, aucun script de migration et aucun changement de donnees/schema n'est dans le perimetre de cette specification.