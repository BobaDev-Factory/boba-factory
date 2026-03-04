# Boba Factory

Boba Factory est un **framework de delivery multi-agent** pour OpenClaw.

Objectif: industrialiser la livraison logicielle (spec, code, review, tests, doc, CI/CD, runbooks, rollback) avec une discipline d’orchestration stricte, réutilisable sur plusieurs projets.

---

## Ce que c’est (et ce que ce n’est pas)

### ✅ Boba Factory
- Un cadre de process pour orchestrer des agents (main + subagents)
- Un point d’entrée session unique (`BOOT.md`)
- Des règles de reprise, lock, contexte actif, qualité, gouvernance Jira/GitHub
- Une structure multi-projet (`projects/<ProjectName>/...`)

### ❌ Boba Factory
- Ce n’est pas un repo applicatif métier
- Ce n’est pas l’endroit pour stocker les docs/tickets/reports d’un projet spécifique

> Les données projet restent dans leurs repos respectifs.

---

## Prérequis

- OpenClaw installé et fonctionnel
- Git installé
- Accès réseau à GitHub + Jira
- Un compte GitHub (PAT recommandé)
- Un compte Jira (email + API token)

Optionnel mais recommandé:
- `gh` (GitHub CLI)

---

## Installation

### Option simple (one-liner)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BobaDev-Factory/boba-factory/main/install.sh)
```

Le script:
1. clone/met à jour `boba-factory` dans `~/.openclaw/workspace/boba-factory`
2. pose les questions de configuration
3. génère `config/local.env` (local, gitignored)
4. injecte les métadonnées runtime en haut de `BOOT.md`
5. ajoute le pointeur Boba Factory dans `~/.openclaw/workspace/AGENTS.md`
6. initialise les protections git (`.gitignore`, hooks si configurés)

---

## Activation dans une session OpenClaw

Dans une nouvelle session, utilise une instruction explicite:

> `Lis /home/<user>/.openclaw/workspace/boba-factory/BOOT.md et applique-le à la lettre.`

Le process demandé dans `BOOT.md` pilote ensuite la reprise:
- sélection projet
- chargement de `ACTIVE_CONTEXT`
- lock projet
- checks connectivité
- résumé readiness

---

## Structure recommandée

```txt
~/.openclaw/workspace/
  boba-factory/
    BOOT.md
    install.sh
    config/
      local.env          # local uniquement (gitignored)
    projects/
      .gitkeep
      <ProjectName>/
        .boba/
          ACTIVE_CONTEXT.json
          LOCK
          reports/
```

- `projects/` est versionné comme dossier, mais son contenu est ignoré
- `ACTIVE_CONTEXT` et `LOCK` sont **par projet**

---

## Accès requis (Jira / GitHub)

Le script stocke ces infos dans `config/local.env`:

- `JIRA_BASE_URL`
- `JIRA_PROJECT_KEY`
- `JIRA_EMAIL`
- `JIRA_TOKEN`
- `GITHUB_ORG`
- `GITHUB_PAT`
- `GITHUB_TOKEN_MODE`

> `config/local.env` est gitignored et ne doit jamais être commité.

### Comment récupérer les accès

#### Jira API token
1. Aller sur [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Créer un token API
3. Utiliser:
   - `JIRA_EMAIL` = email Atlassian
   - `JIRA_TOKEN` = token généré

#### GitHub PAT
1. Aller sur GitHub → Settings → Developer settings → Personal access tokens
2. Créer un token (fine-grained ou classic selon ton besoin)
3. Scopes minimum usuels:
   - repo read/write
   - pull requests/issues selon workflow
4. Utiliser `GITHUB_PAT` dans `config/local.env`

---

## Sécurité

- Ne jamais commit `config/local.env`
- Un hook pre-commit est fourni pour bloquer:
  - `config/local.env`
  - patterns courants de tokens/secrets
- Pour vérifier:

```bash
cd ~/.openclaw/workspace/boba-factory
git status --short
git ls-files config
```

Tu dois voir au maximum `config/.gitkeep` versionné.

---

## Workflow recommandé (résumé)

1. Start session + charger `BOOT.md`
2. Choisir le projet dans `projects/`
3. Charger contexte + lock projet
4. Appliquer pipeline:
   - Spec → Code → Review → Browser/E2E Test → Test → Doc → décision orchestrateur
5. Mettre à jour reports **projet** (pas framework)
6. Libérer lock en fin de session

---

## Dépannage rapide

### Le one-liner ne marche pas
- Vérifier connectivité réseau
- Vérifier que le repo est accessible (public ou auth requise)

### Jira/GitHub KO pendant reprise
- Vérifier `config/local.env`
- Vérifier token expiré/révoqué
- Vérifier URL/key Jira et org GitHub

### Lock bloqué
- Vérifier `projects/<ProjectName>/.boba/LOCK`
- appliquer la procédure du runbook `docs/runbooks/SESSION_RECOVERY.md`

---

## Philosophie

Boba Factory privilégie:
- clarté d’exécution,
- responsabilité explicite par agent,
- preuve avant affirmation,
- réduction du bruit et des coûts tokens,
- séparation stricte framework vs données projet.
