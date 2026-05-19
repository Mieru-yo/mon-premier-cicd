# NOTES TP S4

## 3.1 - Expérience fail-fast (fail-fast: false)
Commit de test: 7028671

1. test(18) est-il annulé quand test(20) échoue ?
Réponse: Non. Avec fail-fast: false, le job Node 18 continue et se termine.

2. Le job report démarre-t-il malgré l'échec de test(20) ?
Réponse: Oui. Le job report utilise if: always() et needs: [lint, test].

3. Que contient le Step Summary dans le rapport ?
Réponse: Un tableau de couverture par version Node (18/20), puis un statut global CI (succès/échec).

4. Quel est l'exit code final du workflow ?
Réponse: Échec (code 1) lorsque lint ou test n'est pas success.

## 3.1 - Expérience fail-fast (fail-fast: true)
Commit de test: 205333f

Observation attendue: dès qu'une variante matrix échoue, l'autre peut être annulée.

## 3.2 - Expérience concurrency
Commits envoyés rapidement: 188791e, 9ac6ab1, 0226b3a

Observation attendue: en envoyant 3 commits rapidement, les runs obsolètes sont annulés et seul le plus récent va au bout.

## 3.3 - Download-artifact
Observation attendue: les artefacts coverage-node-18 et coverage-node-20 sont téléchargeables et les rapports sont en général identiques.

## Challenge 1 - Path filters
Commit configuration path filters: 5fe7cd5
Commit README only (ne doit pas déclencher): 68c29ba
Commit src change (doit déclencher): 339a8ec

Risque d'un filtre trop restrictif:
Si un fichier critique est oublié dans la liste paths (ex: config de build, scripts, fichiers de test), le pipeline peut ne pas se lancer alors que le comportement applicatif a changé.

## Challenge 2 - Outputs entre jobs
Commit implementation: b8a1bfe

Approche utilisée:
- Le job matrix test publie les artefacts coverage-node-18 et coverage-node-20.
- Un job intermédiaire non-matrix coverage-output télécharge les artefacts et calcule le lines pct (Node 18), puis expose la valeur via GITHUB_OUTPUT.
- Le job report lit needs.coverage-output.outputs.lines et affiche un statut SUCCESS/ECHEC dans le Step Summary.

## Challenge 3 - Reusable Workflow
Commit implementation: 06b5d7f

Résultat:
- Le job test est extrait dans .github/workflows/test-reusable.yml
- Le workflow principal .github/workflows/ci.yml appelle ce workflow via uses: ./.github/workflows/test-reusable.yml
- La matrice Node (18/20) est portée par le workflow réutilisable

## Challenge ultime - Composite Action
Commit implementation: 06b5d7f

Résultat:
- Action créée dans .github/actions/setup-node-cached/action.yml
- Elle encapsule checkout + setup-node (cache npm) + npm ci
- Le job lint et le workflow réutilisable test utilisent cette action locale
