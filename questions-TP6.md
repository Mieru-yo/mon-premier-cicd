### Partie A - Concepts fondamentaux

**(Q1)**
Un linter (ESLint) verifie la qualite statique du code: erreurs potentielles, anti-patterns, conventions de code. Un formatter (Prettier) normalise uniquement la mise en forme (espaces, guillemets, virgules, retours a la ligne). Oui, ils peuvent entrer en conflit si ESLint impose des regles de style que Prettier reformate differemment. On resolt ce conflit en separant les responsabilites: Prettier pour le format, ESLint pour la qualite logique, et en ajoutant eslint-config-prettier pour desactiver les regles ESLint de style incompatibles.

**(Q2)**
SemVer contient MAJOR.MINOR.PATCH.

- MAJOR: changement incompatible (breaking change), ex: remplacer /calc/:op/:a/:b par un nouveau schema qui casse les clients existants.
- MINOR: ajout retrocompatible, ex: ajout d'une operation modulo sans casser add/subtract/multiply/divide.
- PATCH: correction retrocompatible, ex: correction d'un message d'erreur ou d'un bug de validation sans modifier le contrat API.

**(Q3)**
Un Conventional Commit est un message de commit structure (type(scope): description), ex: feat:, fix:, chore:, refactor:. Ce format permet aux outils (semantic-release, generateurs de changelog) de determiner automatiquement le niveau de version (MAJOR/MINOR/PATCH) et de generer un CHANGELOG coherent sans tri manuel commit par commit.

### Partie A - Vrai/Faux - Justifiez systématiquement

**(1.)**
FAUX. Un code peut s'executer sans erreur runtime et pourtant violer des regles lint (quality, maintainability, style strict). Avec --max-warnings=0, meme des warnings font echouer le pipeline.

**(2.)**
FAUX. Prettier ne detecte pas les bugs logiques, il formate. ESLint peut detecter certaines erreurs logiques/statique mais n'est pas un moteur de test fonctionnel.

**(3.)**
FAUX. Un commit de typo README (docs) ne devrait pas declencher un bump PATCH applicatif dans une strategie stricte. En pratique semantic-release peut etre configure pour ignorer docs ou produire no release selon les regles choisies.

**(4.)**
VRAI. Le tag Git v2.0.0 identifie la version source; le tag Docker :v2.0.0 identifie l'image executable correspondante. Garder les deux synchronises est une bonne pratique de tracabilite.

**(5.)**
FAUX. Les tags ne sont pas pousses automatiquement par git push classique. Il faut git push --tags ou pousser explicitement un tag.

### EX.2 - ESLint + Prettier dans le pipeline

**(Q4)**
Commandes lancees (ordre):

1. npm install --save-dev eslint
2. npx eslint --init (choix module commonjs, node, syntaxe moderne, verifier les problemes)
3. npm install --save-dev prettier eslint-config-prettier
4. ajout des scripts lint/format dans package.json
5. integration dans ci.yml

**(Q5)**
Violations testees dans src/calculator.js pour l'exercice: usage de var, variable non utilisee, comparaison ==. Au lancement de npm run lint, ESLint signale des erreurs avec numero de ligne et regle enfreinte (no-var, no-unused-vars, eqeqeq) et retourne un code de sortie non nul.

**(Q6)**
Configuration .prettierrc choisie:

1. singleQuote: true, pour rester coherent avec le style deja present.
2. semi: true, pour expliciter les fins d'instruction.
3. trailingComma: es5, pour des diffs plus propres.
4. printWidth: 100, pour limiter les retours ligne excessifs.
   Avec npm run format:check, Prettier echoue si un fichier est mal formate.

**(Q7)**
Structure du job lint dans ci.yml:

1. checkout du code
2. setup node + cache npm
3. npm ci
4. npm run lint
5. npm run format:check
   Cet ordre garantit que la dependance est installee avant les controles, puis que la qualite statique et le format sont valides avant d'autoriser les jobs en aval.

**(Q8)**
Avec une violation ESLint intentionnelle, l'etape npm run lint echoue en premier dans le job Lint & Format. Les jobs dependants (ex: docker puis deploiements) ne demarrent pas a cause de needs.

**(Q9)**
Mettre --max-warnings=5 degrade progressivement la qualite. Les warnings s'accumulent, deviennent de la dette technique, et les nouveaux contributeurs ne savent plus ce qui est acceptable. A long terme, le signal qualite est brouille et les vrais problemes passent plus facilement. Une politique zero warning maintient un standard stable.

### EX.3 - SemVer & Conventional Commits

**(Q10)**
4 exemples de commits Conventional Commits utilises:

1. feat: add staging and production deploy jobs
2. fix: remove forced lint failure from calculator
3. chore: trigger staging/prod deploy flow
4. refactor: simplify workflow summary generation
   Le type est choisi selon l'intention: fonctionnalite, correction, maintenance, restructuration.

**(Q11)**
Avec commitlint + Husky, un message invalide (ex: ajout truc) est refuse au hook commit-msg avec une erreur du type "subject may not be empty" ou "type may not be empty" selon le message. Correction: refaire le commit avec un format valide (ex: chore: update docs section).

**(Q12)**
Analyse SemVer depuis l'historique:

- presence de commits feat -> au moins MINOR
- presence de commits fix -> PATCH
- aucun BREAKING CHANGE explicite observe
  Donc la prochaine version calculee automatiquement est un increment MINOR par rapport a la derniere version publiee. Si aucune release precedente n'existe, une premiere release v1.0.0 est coherente pour stabiliser la base.

**(Q13)**
Le collegue a tort dans ce cas. Ajouter un parametre optionnel retrocompatible est un MINOR, pas MAJOR. Un MAJOR est reserve aux ruptures de compatibilite (clients existants casses sans adaptation).

### EX.4 - Release automatique sur GitHub

**(Q14)**
Structure release.yml:

1. trigger sur push de tags v*.*.\*
2. permissions contents: write et packages: write
3. checkout
4. generation changelog (git-cliff)
5. creation release GitHub (softprops/action-gh-release)
6. build/push image Docker tag version + latest
   Les permissions sont necessaires pour publier release/tags et pousser les images dans GHCR.

**(Q15)**
Pour v1.0.0: creation du tag local, push du tag, declenchement workflow release, generation du changelog, publication de la release GitHub, puis build/push Docker en v1.0.0 et latest.

**(Q16)**
Le CHANGELOG contient les sections derivees des commits (features, fixes, maintenance) avec references de commits. C'est globalement coherent. Amelioration possible: normaliser encore davantage les scopes de commit pour des sections plus lisibles.

**(Q17)**
Conserver v1.0.0 ET latest est essentiel:

- v1.0.0: reproductibilite stricte pour rollback/audit.
- latest: simplicite pour les environnements qui suivent la derniere stable.
  On utilise v1.0.0 en production controlee, et latest surtout pour dev/integration rapide.

### EX.5 - Reflexion & Recherche

**(Q18)**
Arguments objectifs pour adopter Prettier:

1. reduction des debats de style en revue de code.
2. diffs plus petits et plus lisibles.
3. onboarding plus rapide avec un style unique.
4. gain de temps: la machine gere le format, les humains se concentrent sur la logique.
   Ce n'est pas une question de "bon" ou "mauvais" style personnel, mais de coherence d'equipe et d'efficacite.

**(Q19)**
Si la compatibilite est cassee, la prochaine version est MAJOR: v4.0.0 (depuis v3.2.1). Il faut communiquer clairement:

1. nature de la rupture
2. endpoints/contrats impactes
3. guide de migration
4. delai de support de l'ancienne version

**(Q20)**
git-cliff genere surtout un CHANGELOG a partir des commits et tags existants. semantic-release va plus loin: il calcule la version, cree le tag, publie la release et peut declencher des plugins de publication. L'outil qui automatise completement tag + release sans intervention manuelle est semantic-release.

**(Q21)**
Exemple de regle commitlint personnalisee pour longueur minimale du message (subject):

- type-empty: [2, 'never']
- subject-empty: [2, 'never']
- header-min-length: [2, 'always', 10]
  Le hook Husky commit-msg execute commitlint sur le message au moment du commit et bloque les messages invalides avant qu'ils n'entrent dans l'historique.
