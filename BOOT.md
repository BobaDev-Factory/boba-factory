# BOOT.md — Boba Factory v2 (Session Entrypoint)

<!-- BOBA_FACTORY:GENERATED:START -->
- Owner: **BobaMaster**
- Main agent: **Boba**
- GitHub org: `BobaDev-Factory`
- Jira: `https://bobacloud.atlassian.net` (project `BDF`)
<!-- BOBA_FACTORY:GENERATED:END -->

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

### S4 — Charger le contexte documentaire minimal (optimisé)
Lire les docs Boba Factory nécessaires à l’orchestration:

1. Reports (résumé opérationnel)
   - `docs/reports/STATUS.md` (si présent)
   - `docs/reports/CHANGELOG-OPERATIONS.md` (si présent)
2. Process (règles d’exécution)
   - `docs/process/MULTI_AGENT_OPERATING_MODEL.md` (si présent)
   - `docs/process/AGENT_DELIVERABLE_CONTRACT.md` (si présent)
   - `docs/process/AGENT_CATALOG.md` (si présent)
3. Runbooks (procédures)
   - `docs/runbooks/OPENCLAW_BOOTSTRAP.md` (si présent)

Si un fichier est absent: continuer la reprise et le signaler dans le résumé S8.

### S5 — Déclarer pipeline actif
Pipeline par défaut:
- `Spec → Code → Review → Browser/E2E Test → Test (lint/unit/typecheck) → Doc → décision orchestrateur`

Règles:
- 1 agent = 1 mission claire
- pas de merge direct par sous-agent
- `Terminé(e)` interdit sans GO explicite humain

### S6 — Vérifier connectivité (non bloquante)
Vérifier les accès définis dans `config/local.env`:
- Jira (`JIRA_BASE_URL`, `JIRA_PROJECT_KEY`, `JIRA_EMAIL`, `JIRA_TOKEN`)
- GitHub (`GITHUB_ORG`, `GITHUB_PAT` ou auth `gh`)

La non-connectivité Jira/GitHub ne bloque pas la reprise:
- marquer l’état `degraded`
- inclure l’alerte dans le résumé S8

### S7 — Mini résumé état projet
Publier un résumé court:
- projet sélectionné
- `repo/sprint/current_ticket/execution_mode` depuis `ACTIVE_CONTEXT`
- état Jira rapide (sprint actif + tickets clés: En cours / À tester)
- état connectivité (Jira/GitHub: OK ou KO)

### S8 — Readiness message
Avant toute action projet, publier:
- mode
- projet + lock
- contexte actif
- prochaine étape

Si un point critique échoue: `blocked` + stop + demander confirmation explicite à l’Owner.

---

## Politique multi-projet

- Une session peut travailler sur plusieurs projets, mais un seul lock actif à la fois.
- Changement de projet = release lock courant + recharge S1→S8 sur le nouveau projet.

## Catalogue agents (liste complète)

### Leadership
- **Owner (humain)**: autorité produit, validation finale ticket/sprint.
- **Main agent (orchestrateur)**: coordination, gating, intégration, décision finale.

### Core engineering agents
- **Atlas**: spec, scope, acceptance criteria, découpage backlog/tickets.
- **Forge-Backend**: implémentation backend/API/DB/migrations.
- **Forge-Frontend**: implémentation frontend React/UI.
- **Sentinel**: review bugs/sécurité/performance/style.
- **Weaver**: tests navigateurs (Playwright E2E), uniquement `e2e/`.
- **Pulse**: lint/tests/typecheck/smoke avec commandes reproductibles.
- **Scribe**: documentation (README/changelog/runbooks).

### Extended delivery agents
- **Helm**: release/ops (CI/CD, checks déploiement, rollback readiness).
- **Aegis**: sécurité (hardening, secrets, auth/session risk checks).
- **Quarry**: data/DB (migrations, safety query, rollback-safe DB changes).

### Product / business / creative agents
- **Prism**: product analysis (problème, valeur, KPI).
- **Mosaic**: UX/UI design (flows, wireframes, design QA).
- **Quill**: content writer (copy produit/doc/in-app).
- **Echo**: social media (posts/canaux/calendrier).
- **Vector**: marketing (positionnement, ICP/personas, GTM).
- **Radar**: SEO (keywords, briefs SEO, on-page reco).
- **Beacon**: analytics (tracking plan, funnels, instrumentation KPI).
- **Bridge**: sales enablement (decks, one-pagers, objection handling).
