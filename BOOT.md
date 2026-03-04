# BOOT.md — Boba Factory session entrypoint

Ce fichier est le point d'entrée unique des nouvelles sessions pour Boba Factory.

## Convention projects/

- `projects/` contient 1 dossier par produit/projet (ex: `projects/Rynade/`).
- Chaque dossier projet contient les repos git des applications du projet.
  - ex: `projects/Rynade/rynade-backoffice-web`
  - ex: `projects/Rynade/rynade-core-api`
- Le contenu de `projects/` est ignoré par git (local-only), pour permettre de cloner et travailler librement sans polluer le repo Boba Factory.

## Règle

- Toute nouvelle session doit utiliser ce fichier comme point d'entrée process.
