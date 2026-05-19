# NOTES TP S4

## 3.1 - Experience fail-fast (fail-fast: false)
Commit de test: 7028671

1. test(18) est-il annule quand test(20) echoue ?
Reponse: Non. Avec fail-fast: false, le job Node 18 continue et se termine.

2. Le job report demarre-t-il malgre l'echec de test(20) ?
Reponse: Oui. Le job report utilise if: always() et needs: [lint, test].

3. Que contient le Step Summary dans le rapport ?
Reponse: Un tableau de couverture par version Node (18/20), puis un statut global CI (succes/echec).

4. Quel est l'exit code final du workflow ?
Reponse: Echec (code 1) lorsque lint ou test n'est pas success.

## 3.1 - Experience fail-fast (fail-fast: true)
Commit de test: 205333f

Observation attendue: des qu'une variante matrix echoue, l'autre peut etre annulee.

## 3.2 - Experience concurrency
Commits envoyes rapidement: 188791e, 9ac6ab1, 0226b3a

Observation attendue: en envoyant 3 commits rapidement, les runs obsoletes sont annules et seul le plus recent va au bout.

## 3.3 - Download-artifact
Observation attendue: les artefacts coverage-node-18 et coverage-node-20 sont telechargeables et les rapports sont en general identiques.

## Challenge 1 - Path filters
Commit configuration path filters: 5fe7cd5
Commit README only (ne doit pas declencher): 68c29ba
Commit src change (doit declencher): 339a8ec

Risque d'un filtre trop restrictif:
Si un fichier critique est oublie dans la liste paths (ex: config de build, scripts, fichiers de test), le pipeline peut ne pas se lancer alors que le comportement applicatif a change.

## Challenge 2 - Outputs entre jobs
Commit implementation: b8a1bfe

Approche utilisee:
- Le job matrix test publie les artefacts coverage-node-18 et coverage-node-20.
- Un job intermediaire non-matrix coverage-output telecharge les artefacts et calcule le lines pct (Node 18), puis expose la valeur via GITHUB_OUTPUT.
- Le job report lit needs.coverage-output.outputs.lines et affiche un statut SUCCESS/ECHEC dans le Step Summary.
