# NOTES TP S4

## 3.1 - Experience fail-fast (fail-fast: false)
1. test(18) est-il annule quand test(20) echoue ?
Reponse: Non. Avec fail-fast: false, le job Node 18 continue et se termine.

2. Le job report demarre-t-il malgre l'echec de test(20) ?
Reponse: Oui. Le job report utilise if: always() et needs: [lint, test].

3. Que contient le Step Summary dans le rapport ?
Reponse: Un tableau de couverture par version Node (18/20), puis un statut global CI (succes/echec).

4. Quel est l'exit code final du workflow ?
Reponse: Echec (code 1) lorsque lint ou test n'est pas success.

## 3.1 - Experience fail-fast (fail-fast: true)
Observation attendue: des qu'une variante matrix echoue, l'autre peut etre annulee.

## 3.2 - Experience concurrency
Observation attendue: en envoyant 3 commits rapidement, les runs obsoletes sont annules et seul le plus recent va au bout.

## 3.3 - Download-artifact
Observation attendue: les artefacts coverage-node-18 et coverage-node-20 sont telechargeables et les rapports sont en general identiques.
