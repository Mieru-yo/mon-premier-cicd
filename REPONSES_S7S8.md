# Réponses — TP S7/S8 Environnements & Déploiement

## EX.1 — Questions de cours

### Partie A

**Q1 [CONCEPT]**
Un environnement de staging est une préproduction qui reproduit la production au plus proche pour valider le comportement réel avant mise en ligne. Un environnement de production est l'environnement utilisé par les utilisateurs finaux et soumis à des exigences fortes de disponibilité et de sécurité.
Exemple concret : staging utilise une base de test avec des données anonymisées, alors que production utilise la vraie base client.

**Q2 [CONCEPT]**
Une protection rule sur un GitHub Environment est une règle qui encadre l'exécution des jobs liés à cet environnement (approbation obligatoire, wait timer, reviewers autorisés). Elle résout le risque de déploiement non contrôlé en production (push accidentel, approbation trop rapide, déploiement hors fenêtre).

**Q3 [CONCEPT]**
Cycle complet avec approbation manuelle :
1. Le développeur pousse sur main.
2. Le pipeline exécute lint/tests/build automatiquement.
3. Le job lié à `environment: production` est mis en attente par GitHub.
4. Un reviewer autorisé reçoit la demande d'approbation.
5. Si approuvé, le job de déploiement production démarre.
6. Le pipeline effectue un health-check post-déploiement.
7. En cas de succès, le run se termine en vert ; sinon il échoue et déclenche rollback/procédure d'urgence.

### Partie B — Vrai/Faux

1. **FAUX** — staging doit être le plus proche possible de prod, pas volontairement différent.
2. **VRAI** — Blue/Green permet de rerouter le trafic vers l'ancienne version quasi instantanément.
3. **FAUX** — Canary commence sur une petite part du trafic, pas 100%.
4. **VRAI** — les secrets d'environnement ont priorité quand un job cible cet environnement.
5. **FAUX** — `environment:` active aussi règles, approbations, secrets et historique de déploiement.

---

## EX.2 — GitHub Environments

**Q4 [APPLICATION]**
Paramètres retenus pour `staging` :
1. Pas d'approbation manuelle : objectif validation rapide continue.
2. Secrets dédiés staging (`RENDER_STAGING_HOOK`, `RENDER_STAGING_HEALTH_URL`) : isolation des risques.
3. Pas de wait timer : accélérer le feedback.

**Q5 [APPLICATION]**
Reviewer `production` : le propriétaire du repo (mainteneur principal). En équipe réelle, ce rôle revient au lead/owner car il est responsable du risque de mise en prod.

**Q6 [RÉFLEXION]**
Le wait timer (ex. 10 min) est utile juste après une montée de version majeure pour laisser le temps d'observer les métriques staging (erreurs, latence), vérifier les dashboards et laisser une fenêtre d'annulation avant production.

**Q7 [APPLICATION]**
Structure `deploy-staging` :
1. `needs: [docker]` pour n'exécuter staging qu'après build/push image réussi.
2. `environment: staging` pour lier secrets et règles.
3. `run:` déclenche un Deploy Hook Render via `curl` puis health-check `/health` en boucle.

**Q8 [APPLICATION]**
Lors d'un push sur main : lint/tests/docker s'exécutent d'abord. Ensuite `deploy-staging` démarre automatiquement. Puis `deploy-production` se met en attente avec demande d'approbation GitHub Environment ; l'approbation est demandée juste avant l'exécution effective du job production.

**Q9 [RÉFLEXION]**
Si un reviewer refuse, le job production est marqué non exécuté/échoué selon l'UI de run et ne déploie pas. Le run n'est pas perdu : un nouveau run peut être relancé via nouveau commit ou rerun selon politique.

---

## EX.3 — Déploiement Render

**Q10 [APPLICATION]**
4 infos clés Render :
1. Repo GitHub source : Render doit savoir quel code builder.
2. Runtime/stack (Node) : Render doit choisir l'environnement d'exécution.
3. Build command (ex: `npm ci && npm run test:ci`) : Render doit compiler/installer.
4. Start command (ex: `node src/server.js`) : Render doit savoir quel process lancer.

**Q11 [APPLICATION]**
URL publique : `https://<service-name>.onrender.com` (à remplacer par l'URL réelle du service). La route `/health` répond 200 car l'application expose explicitement cet endpoint dans `src/server.js`.

**Q12 [RÉFLEXION]**
Deux solutions contre cold starts en prod :
1. Passer sur un plan paid avec instance always-on.
2. Mettre un ping de keep-alive contrôlé (monitoring synthétique) en respectant la politique fournisseur.

**Q13 [APPLICATION]**
Approche choisie : Deploy Hook depuis GitHub Actions (plus de contrôle).
Étapes :
1. Créer hook staging et prod dans Render.
2. Stocker les hooks en secrets GitHub Environment.
3. Déclencher `curl -X POST` depuis jobs `deploy-staging` / `deploy-production`.

**Q14 [APPLICATION]**
Health-check post-déploiement implémenté dans le pipeline : boucle `curl` sur `/health` avec timeout progressif. Le job échoue si pas de 200 dans la fenêtre de tentative.

**Q15 [RÉFLEXION]**
AutoDeploy Render : simple, peu de config, mais moins de contrôle orchestration CI.
Deploy Hook depuis Actions : plus verbeux, mais meilleur contrôle des dépendances (`needs`), approbations, health-checks, et traçabilité dans un seul pipeline.

---

## EX.4 — Réflexion

**Q16 [RÉFLEXION]**
Supprimer staging augmente fortement le risque de régression en prod, car les tests unitaires ne couvrent pas tous les cas d'intégration (config, réseau, dépendances externes, secrets, comportement runtime). Le staging sert de filet de sécurité réaliste avant exposition utilisateur.

**Q17 [RÉFLEXION]**
Pour une fonctionnalité paiement critique : Canary. On limite le risque financier en exposant progressivement, on surveille KPI (taux d'échec paiement, latence, erreurs), puis montée graduelle ou rollback rapide si anomalie.

**Q18 [RÉFLEXION]**
Procédure d'urgence :
1. Déclarer incident et geler les déploiements.
2. Basculer rollback vers version stable (ou reroute Blue/Green).
3. Vérifier retour service (`/health`, erreurs 500, taux succès paiements).
4. Communiquer statut interne/externe.
5. Ouvrir post-mortem, corriger cause racine, ajouter garde-fous (rules/approvals/tests).

**Q19 [RÉFLEXION]**
Stratégie secrets 3 environnements x 2 services :
1. Secrets communs non sensibles en variables repo.
2. Secrets sensibles séparés par environnement (`DEV_*`, `STAGING_*`, `PROD_*`) via GitHub Environments.
3. Séparer API/DB (`API_URL`, `DB_URL`, `DB_USER`, `DB_PASSWORD`) par environnement.
4. Limiter accès production aux reviewers autorisés uniquement.

---

## EX.5 — Recherche autonome

**Q20 [RECHERCHE]**
GitHub Deployments API sert à créer/mettre à jour des objets de déploiement rattachés à commit/environnement, avec statuts (`in_progress`, `success`, `failure`). Elle permet de tracer précisément qui a déployé quoi, où et quand dans l'UI GitHub. Cas d'usage : pipeline qui publie sur staging puis met à jour le statut de déploiement automatiquement.

**Q21 [RECHERCHE]**
`vars.*` : valeurs non sensibles, lisibles dans workflows/logs selon usage. `secrets.*` : valeurs sensibles masquées dans logs et stockées de manière sécurisée.
Utiliser `vars` pour config non secrète (ex: `REGION`, `APP_NAME`).
Utiliser `secrets` pour données sensibles (ex: `RENDER_PROD_HOOK`, `DB_PASSWORD`).

**Q22 [RECHERCHE]**
Un Preview Environment Render crée un environnement temporaire par Pull Request avec URL dédiée. Il permet de tester la PR en conditions réelles avant merge (QA/review produit). C'est très utile pour la revue de code fonctionnelle. Il ne remplace pas totalement staging : staging reste l'environnement d'intégration stable partagé.

---

## Challenge (pipeline complet) — État d'implémentation repo

Pipeline implémenté : tests -> build/push Docker -> deploy staging -> approbation -> deploy production.
Health-check staging et production inclus. Déploiement prod bloqué si staging échoue. Secrets d'environnement distincts attendus :
- `RENDER_STAGING_HOOK`
- `RENDER_STAGING_HEALTH_URL`
- `RENDER_PROD_HOOK`
- `RENDER_PROD_HEALTH_URL`
