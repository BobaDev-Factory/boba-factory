# Boba Factory

Boba Factory est la base de refonte des process d'orchestration, multi-agents, gouvernance outils, et optimisation token.

## Installation (one-liner)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BobaDev-Factory/boba-factory/main/install.sh)
```

## Structure

- `BOOT.md` : point d'entrée unique des sessions
- `install.sh` : script d'installation à la racine
- `projects/` : dossiers projets locaux (contenu ignoré par git)

## Convention projets

Chaque projet vit dans `projects/<ProjectName>/` et contient ses repos applicatifs.

Exemple:

- `projects/Rynade/rynade-backoffice-web`
- `projects/Rynade/rynade-core-api`
