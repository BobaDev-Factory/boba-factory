# BOOT.md — Boba Factory v2 (Session Entrypoint)

Ce fichier est la source unique de process pour les sessions Boba Factory.

## Scope du repo

- `boba-factory` contient uniquement le framework/process.
- Les infos projet (tickets, specs, rapports, runbooks métier) restent dans les repos projet.

## Convention `projects/`

- `projects/<ProjectName>/` contient les repos git du projet.
- Exemple:
  - `projects/Rynade/rynade-backoffice-web`
  - `projects/Rynade/rynade-core-api`
- État local par projet (non versionné):
  - `projects/<ProjectName>/.boba/ACTIVE_CONTEXT.json`
  - `projects/<ProjectName>/.boba/LOCK`

---

## Contrat de reprise S1 → S8 (obligatoire)

### S1 — Sélection du projet
Au démarrage de session:
1. lister les dossiers de `projects/`
2. demander à l’utilisateur quel projet continuer
3. basculer le contexte sur `projects/<ProjectName>/`

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
- lock stale: demander confirmation utilisateur avant override

### S4 — Charger le process Boba Factory (optimisé)
Ne pas relire `SOUL.md`, `USER.md` ou ce fichier (déjà chargés par OpenClaw/session).

Lire uniquement les docs process strictement nécessaires dans `boba-factory`:
1. `BOOT.md` (référence active)
2. `templates/workspace/AGENTS.block.md` (règle de pointer)

Tout autre document process est lu uniquement si requis par la tâche.

### S5 — Vérifier connectivité via `config/local.env`
Vérifier les accès définis dans `config/local.env`:
- Jira (`JIRA_BASE_URL`, `JIRA_PROJECT_KEY`, `JIRA_EMAIL`, `JIRA_TOKEN`)
- GitHub (`GITHUB_ORG`, `GITHUB_PAT` ou auth `gh`)

Ces accès doivent être réutilisés pour toutes actions Jira/GitHub.

### S6 — Mini résumé état projet
Publier un résumé très court:
- projet sélectionné
- `repo/sprint/current_ticket/execution_mode` depuis `ACTIVE_CONTEXT`
- état Jira rapide (sprint actif + tickets clés: En cours / À tester)

### S7 — Déclarer pipeline actif
Pipeline par défaut:
- `Spec → Code → Review → Test → Doc → décision orchestrateur`

Règles:
- 1 agent = 1 mission claire
- pas de merge direct par sous-agent
- `Terminé(e)` interdit sans GO explicite humain

### S8 — Readiness message
Avant toute action projet, publier:
- mode
- projet + lock
- contexte actif
- prochaine étape

Si un point échoue: `blocked` + stop.

---

## Politique multi-projet

- Une session peut travailler sur plusieurs projets, mais un seul lock actif à la fois.
- Changement de projet = release lock courant + recharge S1→S8 sur le nouveau projet.

## Section générée par install.sh
<!-- BOBA_FACTORY:GENERATED:START -->
## Installed configuration (generated)

- Owner: **BobaMaster**
- Main agent: **Boba**
- GitHub org:   `BobaDev-Factory`
- Jira: `https://bobacloud.atlassian.net` (project `BDF`)

## Agent routing baseline

- Orchestrator (Boba): planning, gating, integration, final decision
- Spec Agent (Atlas): scope + acceptance criteria
- Code Agents (Forge-Backend / Forge-Frontend): implementation
- Review Agent (Sentinel): bugs/security/perf/style
- Test Agent (Pulse): lint/tests/typecheck/e2e evidence
- Doc Agent (Scribe): docs/runbook/changelog

Model policy is defined by BOOT.md runtime instructions and can be adjusted per mission.
<!-- BOBA_FACTORY:GENERATED:END -->
