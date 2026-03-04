# BOOT.md — Boba Factory v2.1 (Session Entrypoint)

<!-- BOBA_FACTORY:GENERATED:START -->
- Owner: **BobaMaster**
- Main agent: **Jarvis**
- GitHub org: `BobaDev-Factory`
- Jira: `https://bobacloud.atlassian.net` (project `BF`)
<!-- BOBA_FACTORY:GENERATED:END -->

Ce fichier est la source unique de process pour les sessions Boba Factory.

Mission Boba Factory : industrialiser la livraison logicielle (spec, code, review, test, doc, CI/CD, runbooks, rollback) avec une discipline multi-agent stricte.

## Scope du repo

- `boba-factory` contient uniquement le framework/process.
- Les infos projet (tickets, specs, rapports, runbooks métier) restent dans les repos projet.
- Les spécifications projet doivent être isolées en:
  - `SPEC_LIGHT.md` par projet pour la reprise session
  - specs complètes dans les repos projet (jamais dans `boba-factory`).

## Convention `projects/`

- `projects/<ProjectName>/` contient les repos git du projet.
- État local par projet (non versionné):
  - `projects/<ProjectName>/.boba/ACTIVE_CONTEXT.json`
  - `projects/<ProjectName>/.boba/LOCK`
  - `projects/<ProjectName>/.boba/active-tasks.json`
  - `projects/<ProjectName>/.boba/proposed-tasks.json`
  - `projects/<ProjectName>/.boba/cron.json`

---

## Contrat de reprise S1 → S8 (obligatoire)

### S1 — Sélection du projet
1. Lister les dossiers de `projects/`
2. Demander à l’utilisateur quel projet continuer
3. Basculer le contexte sur `projects/<ProjectName>/`

### S2 — Charger le contexte actif projet
Lire/initialiser `projects/<ProjectName>/.boba/ACTIVE_CONTEXT.json` avec au minimum:
- `project`
- `repo`
- `sprint`
- `current_ticket`
- `execution_mode` (`step_confirm` par défaut)
- `last_updated_at`

### S3 — Acquérir le lock projet
Créer/valider `projects/<ProjectName>/.boba/LOCK`.

Clé lock standard:
- `{project}:{repo}:{sprint}`

Règles:
- lock obligatoire avant action mutante (Jira, code, spawn agent, commit/push)
- lock stale: demander confirmation explicite à l’Owner avant override
- changement de projet: release lock courant avant nouveau lock

### S4 — Charger le contexte documentaire (reports/process/runbooks)
Lire les docs nécessaires à l’orchestration:
1. Reports
   - `docs/reports/STATUS.md` (si présent)
2. Process
   - `docs/process/MULTI_AGENT_OPERATING_MODEL.md` (si présent)
   - `docs/process/AGENT_DELIVERABLE_CONTRACT.md` (si présent)
   - `docs/process/AGENT_CATALOG.md` (si présent)
   - `docs/process/QUALITY_GATES.md` (si présent)
   - `docs/process/RUNTIME_AUTOMATION.md` (si présent)
3. Runbooks
   - `docs/runbooks/SESSION_RECOVERY.md` (si présent)
4. Project light spec (selected project)
   - `projects/<ProjectName>/.boba/specs/SPEC_LIGHT.md` (si présent)

Si un fichier est absent: continuer et le signaler en S8.

### S5 — Déclarer pipeline actif + règles
Pipeline par défaut:
- `Spec → Code → Review → Browser/E2E Test → Test (lint/unit/typecheck) → Doc → décision orchestrateur`

Règles:
- 1 agent = 1 mission claire
- aucun merge direct par sous-agent
- orchestrateur = seule autorité d’intégration
- orchestrateur ne code pas, sauf override explicite de l’Owner
- échec d’étape (`fail/blocked`) = stop pipeline + diagnostic + next action

### S6 — Vérifier connectivité (non bloquante)
Vérifier les accès de `config/local.env`:
- Jira: `JIRA_BASE_URL`, `JIRA_PROJECT_KEY`, `JIRA_EMAIL`, `JIRA_TOKEN`
- GitHub: `GITHUB_ORG`, `GITHUB_PAT` (ou auth gh valide)

La non-connectivité n’arrête pas la reprise:
- marquer `degraded`
- inclure l’état dans le résumé S7/S8

Vérifier aussi le statut cron OpenClaw si activé (`projects/<ProjectName>/.boba/cron.json`).

### S7 — Résumé opérationnel court
Publier un résumé compact:
- projet sélectionné
- `repo/sprint/current_ticket/execution_mode` (ACTIVE_CONTEXT)
- Jira rapide: sprint actif + tickets clés (En cours / À tester)
- connectivité: Jira/GitHub = OK/KO

### S8 — Readiness gate
Avant toute action projet, publier:
- mode
- projet + lock
- contexte actif
- prochaine étape

Si un point critique échoue:
- `blocked` + stop
- demander confirmation explicite à l’Owner (nom issu de l’install)

---


### S9 — Charger le runtime des agents
Lire/initialiser:
- `projects/<ProjectName>/.boba/active-tasks.json`
- `projects/<ProjectName>/.boba/proposed-tasks.json`

Classifier l’état runtime:
- `running`
- `blocked`
- `ready_for_review`
- `stale`

### S10 — Exécuter les checks automatiques
Lancer les checks déterministes:
- `scripts/check-agents.sh`
- `scripts/check-dod.sh`

Produire un état:
- `ready_to_merge`
- `needs_retry`
- `needs_human`

### S11 — Décider la prochaine action immédiate
Après S10, l’orchestrateur doit déclencher une action explicite:
- spawn next agent
- retry intelligent
- notification humaine

Interdit de finir la reprise sans `next_action` explicite.

---


## Format de réponse obligatoire après reprise

Après exécution complète de S1→S8, ne pas afficher tout le contexte chargé.
Répondre uniquement avec:

1. Confirmation: reprise exécutée correctement
2. Résumé court de la dernière tâche connue
3. Prochaine étape proposée conforme au process

Format:
- `Reprise OK: <project/repo/sprint/mode>`
- `État agents: <running | blocked | ready>`
- `Prochaine étape: <action unique>`

---

## Clôture de session (obligatoire)

Toujours faire:
1. update report projet (pas global), ex: `projects/<ProjectName>/.boba/reports/SESSION_LOG.md`
2. append changelog projet (pas `docs/reports/PROCESS_CHANGES.md`)
3. mettre à jour `projects/<ProjectName>/.boba/specs/SPEC_LIGHT.md` si scope/décisions/AC ont changé
4. lister 3 prochaines actions exécutables
5. libérer lock de contexte projet (`projects/<ProjectName>/.boba/LOCK`)

Notes:
- `docs/reports/STATUS.md` et `docs/reports/PROCESS_CHANGES.md` sont réservés aux évolutions du framework Boba Factory.
- Ils ne doivent pas être mis à jour pour l’exécution quotidienne d’un projet.

---

## Règles Jira (non négociables)

Transitions obligatoires en cours d’exécution:
- `En cours` dès démarrage du travail
- `À tester` au handoff validation
- `Terminé(e)` uniquement après gates validés + GO explicite Owner

Clôture sprint:
- interdite sans GO explicite Owner

---

## Contrat livrable agent (obligatoire)

Chaque agent doit renvoyer:
1. `summary`
2. `changed_files`
3. `status` (`pass|fail|blocked`)
4. `checks` (commandes + résultats)
5. `next_action`

---

## Politique multi-projet

- Une session peut traiter plusieurs projets, un seul lock actif à la fois.
- Changement de projet => relancer S1→S8 sur le nouveau projet.

---

## Catalogue agents (complet)

### Leadership
- **Owner (humain)**: autorité produit, validation finale ticket/sprint.
- **Main agent (orchestrateur)**: coordination, gating, intégration, décision finale.

### Core engineering
- **Atlas**: spec/scope/AC
- **Forge-Backend**: backend/API/DB
- **Forge-Frontend**: frontend/UI
- **Sentinel**: review bugs/sécurité/perf/style
- **Weaver**: tests navigateur E2E (Playwright)
- **Pulse**: lint/tests/typecheck/smoke
- **Scribe**: docs/changelog/runbooks

### Extended delivery
- **Helm**: release/ops
- **Aegis**: sécurité
- **Quarry**: data/DB

### Product / business / creative
- **Prism**: product analysis
- **Mosaic**: UX/UI
- **Quill**: content
- **Echo**: social
- **Vector**: marketing
- **Radar**: SEO
- **Beacon**: analytics
- **Bridge**: sales enablement
