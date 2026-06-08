# mon-premier-cicd

[![CI Pipeline](https://github.com/Mieru-yo/mon-premier-cicd/actions/workflows/ci.yml/badge.svg)](https://github.com/Mieru-yo/mon-premier-cicd/actions/workflows/ci.yml)

## Description

Pipeline CI/CD Node.js avec qualite code, deploiement staging/production et release automatisee.

## Contribution

### Prerequis

- Node.js 18+
- npm

### Installation

```bash
npm ci
```

### Regles de qualite locales

```bash
npm run lint
npm run format:check
npm test
```

### Format des commits

Le projet suit Conventional Commits.

Exemples valides:

- feat: add divide endpoint docs
- fix: handle invalid operation in server
- chore: update github workflow cache
- refactor: simplify calculator exports

Les hooks Husky + commitlint valident le message au commit.

## Release automatique

### Strategie

- Sur push vers main, semantic-release calcule automatiquement la prochaine version SemVer.
- semantic-release cree le tag Git, met a jour CHANGELOG.md et publie la release GitHub.
- Le workflow de release sur tag v*.*.\* construit et publie l'image Docker avec:
  - le tag de version (ex: v1.0.0)
  - latest

### Secrets GitHub requis

- GITHUB_TOKEN: fourni par GitHub Actions
- GHCR token via GITHUB_TOKEN (packages: write)
- SLACK_WEBHOOK_URL pour la notif Slack (optionnel)
- SONAR_TOKEN pour SonarCloud (challenge)

### Commandes utiles

```bash
npm run release -- --dry-run
```

## Lancer les tests

```bash
npm ci && npm test
```

## Preuve bonus - Notification Slack

Notification reçue lors d'un échec de pipeline CI :

![Notification Slack](notification-slack.png)

## Preuve couverture (demande TP)

La couverture est produite par le job de tests en matrix Node.js 18 et 20.

Où vérifier dans GitHub Actions :

- Ouvrir un run vert du workflow CI
- Descendre à la section Artifacts
- Vérifier la présence de coverage-node-18 et coverage-node-20

Le résumé de couverture est aussi visible dans le Summary des jobs de test.
