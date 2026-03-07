# Jira ↔ GitHub Convention (Boba Factory)

Objectif: faire remonter automatiquement l’activité GitHub dans Jira (branches, commits, PR) sans friction.

## Règle absolue
Toujours inclure la clé ticket Jira (`<KEY>-<NUM>`) dans:
1. le nom de branche
2. le titre de PR
3. les messages de commit

Exemple de clé: `BDF-123`

## Templates obligatoires

### Branches
- Feature: `feature/BDF-123-short-scope`
- Fix: `fix/BDF-123-short-scope`
- Chore: `chore/BDF-123-short-scope`
- Hotfix: `hotfix/BDF-123-short-scope`

### PR title
- `BDF-123 <résumé clair du changement>`

### Commit messages
- `BDF-123 feat(auth): add login endpoint`
- `BDF-123 fix(api): handle 401 refresh`
- `BDF-123 chore(ci): pin pnpm version`

## Règles pipeline agents
- Tout sous-agent qui produit du code DOIT respecter ce format.
- Si `current_ticket` est vide, l’orchestrateur stoppe et demande un ticket avant coding.
- Aucune PR sans clé Jira dans le titre.

## Vérification rapide avant handoff
- [ ] Branche contient `BDF-xxx`
- [ ] PR title contient `BDF-xxx`
- [ ] Au moins un commit contient `BDF-xxx`

## Pourquoi
- Traçabilité automatique Jira
- Avancement sprint visible en temps réel
- Moins d’updates manuels
