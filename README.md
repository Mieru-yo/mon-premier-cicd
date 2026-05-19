# mon-premier-cicd

[![CI Pipeline](https://github.com/Mieru-yo/mon-premier-cicd/actions/workflows/ci.yml/badge.svg)](https://github.com/Mieru-yo/mon-premier-cicd/actions/workflows/ci.yml)

## Description
Premier pipeline CI/CD avec GitHub Actions, Node.js, Jest et ESLint.

## Lancer les tests
```bash
npm ci && npm test
```

## Preuve couverture (demande TP)

La couverture est produite par le job de tests en matrix Node.js 18 et 20.

Où vérifier dans GitHub Actions :
- Ouvrir un run vert du workflow CI
- Descendre à la section Artifacts
- Vérifier la présence de coverage-node-18 et coverage-node-20

Le résumé de couverture est aussi visible dans le Summary des jobs de test.