### Partie A - Concepts

**(Q1)**
`npm audit` analyse les dependances npm (package-lock) et detecte les CVE dans la supply chain JS. Trivy scanne surtout l'image Docker (OS packages, libs, secrets, misconfigurations selon mode). Dans le pipeline, je place d'abord `npm audit` (rapide, avant build image), puis Trivy apres build pour scanner l'artefact deployable final.

**(Q2)**
Le moindre privilege signifie donner a chaque secret seulement le scope minimal necessaire et seulement aux jobs qui en ont besoin.
Exemple 1 : `RENDER_PROD_HOOK` n'est utilise que dans le job de deploiement production, pas dans les jobs lint/test.
Exemple 2 : `SLACK_WEBHOOK_URL` n'est consomme que dans le job de notification, jamais dans les etapes build ou release.

**(Q3)**
Métriques DORA:

1. Deployment Frequency: frequence de mise en prod. Niveau elite: plusieurs deploiements par jour.
2. Lead Time for Changes: temps entre commit et prod. Niveau elite: moins d'un jour.
3. Change Failure Rate: pourcentage de deploiements qui cassent. Niveau elite: 0-15%.
4. MTTR: temps moyen de restauration. Niveau elite: moins d'une heure.
   Le pipeline aide via tests automatiques, quality gates, scans securite, approvals et notifications qui reduisent le risque et accelerent la detection/récupération.

### Partie B - Vrai / Faux

**(1.)**
FAUX. `npm audit --audit-level=high` echoue sur HIGH et CRITICAL, pas uniquement CRITICAL.

**(2.)**
VRAI. Trivy peut detecter des secrets hardcodes dans des fichiers selon le type de scan configure.

**(3.)**
VRAI. `if: failure()` dans un job s'active quand un step precedent de ce meme job a echoue.

**(4.)**
VRAI. Dependabot cree des PR automatiquement mais ne merge pas par defaut sans regles/auto-merge configurees.

**(5.)**
FAUX. Supprimer le fichier ne suffit pas: le secret reste dans l'historique git, il faut rotation/revocation + nettoyage historique si necessaire.

### EX.2 - npm audit + Trivy dans le pipeline

**(Q4)**
Resultat local `npm audit` : 0 vulnerabilites (info/low/moderate/high/critical tous a 0). Donc aucune dependance directe ou transitive vulnerable detectee a ce run.

**(Q5)**
`npm audit` est ajoute dans le job `Lint & Format` avec `--audit-level=high`.
Justification: on bloque sur risques eleves (HIGH/CRITICAL) tout en evitant de bloquer sur LOW/MODERATE. Ce niveau est un compromis securite/velocite.

**(Q6)**
Job `Security (Trivy)` configure avec:

- `image-ref: mon-premier-cicd:scan` pour scanner l'image Docker construite localement dans le job.
- `severity: HIGH,CRITICAL` pour se concentrer sur les risques critiques.
- `format: sarif` + `output: trivy-results.sarif` pour publication Security Tab.
- `ignore-unfixed: true` pour eviter les faux blocages immediats sur CVE sans patch disponible.

**(Q7)**
La dependance est `needs: [docker]` pour `security`. L'ordre est obligatoire car Trivy doit scanner une image deja construite; sans build prealable il n'y a pas d'artefact a analyser.

**(Q8)**
Si Trivy detecte 3 CVE HIGH sur l'image de base non corrigeable immediatement:

1. Documenter explicitement le risque (ticket securite + contexte).
2. Mettre en place une exception temporaire encadree (date d'expiration, owner).
3. Maintenir une alerte Slack/issue hebdo jusqu'a correction image.
4. Chercher image alternative ou mitigation runtime (hardening, suppression packages inutiles).

### EX.3 - Notifications Slack

**(Q9)**
Un job `Notify & Summary` envoie un message Slack en cas d'echec avec: nom du repo, branche, `GITHUB_SHA`, lien du run GitHub Actions, et cause (liste des jobs en echec).

**(Q10)**
Test effectue via erreur pipeline volontaire (violation lint). Notification recue avec indicateur rouge, nom repo, branche, SHA du commit, et lien vers les logs. Le message contient aussi la cause (job(s) failed) pour triage rapide.

**(Q11)**
Notification de succes envoyee apres run complet vert avec indicateur vert, SHA du commit, URL staging et production, et lien run. Difference cle: l'echec envoie la cause detaillee; le succes met en avant les endpoints deployes.

**(Q12)**
3 strategies anti-notification fatigue:

1. Router les alertes par severite/canal (critique vs info).
2. Regrouper les alertes repetitives en resume periodique.
3. Inclure cause exploitable + owner + action attendue pour eviter le bruit non actionnable.

### EX.4 - Observabilite & DORA

**(Q13)**
Estimation sur ce projet:

1. Deployment Frequency: elevee (plusieurs deploys/jour en phase TP) -> proche elite.
2. Lead Time: court (quelques minutes a heures) -> proche elite.
3. Change Failure Rate: moyen (plusieurs runs rouges pendant experimentation) -> a ameliorer.
4. MTTR: bon a moyen (corrections rapides mais plusieurs itérations) -> viser <1h stable.
   Ameliorations: PR templates, strategy de rollback formalisee, reduction des reruns via pre-checks locaux, meilleures regles de branches.

**(Q14)**
UptimeRobot configure en HTTP(S) monitor sur `/health`, intervalle 5 minutes, alerte email immediate. Ce choix donne un compromis reactivite/coût et evite trop de faux positifs.

**(Q15)**
Infos manquantes pour diagnostic incident:

1. Logs applicatifs (Render logs)
2. Metriques infra (CPU/RAM/restarts)
3. Traces de requetes (APM)
4. Historique deploy (GitHub Actions + Deployments API)
5. Evenements externes (provider status pages)
   Chaque source aide a isoler root cause plus vite.

### EX.5 - Reflexion & Recherche

**(Q16)**
Desactiver Trivy est une mauvaise idee. Alternative: garder Trivy actif, bloquer seulement HIGH/CRITICAL, autoriser temporairement `ignore-unfixed`, et gerer les exceptions avec SLA de remediation. On preserve securite et velocite.

**(Q17)**
5 pratiques pour reduire MTTR:

1. Runbooks incident standardises.
2. Alertes actionnables avec owner explicite.
3. Rollback automatisable rapide.
4. Feature flags pour desactivation ciblée.
5. On-call rotation + post-mortems blameless avec actions correctives.

**(Q18)**
Gitleaks detecte les secrets commits (tokens, keys, credentials) dans code/historique. En GitHub Actions, il s'integre comme job de scan avant build/deploy. Il complete `npm audit` (deps) et Trivy (image/CVE) en couvrant un autre axe: fuite de secrets.

**(Q19)**
GitHub Secret Scanning detecte automatiquement de nombreux providers (GitHub tokens, AWS, Azure, Google, Stripe, Slack, etc.). Sur repos prives, la disponibilite depend du plan/fonctionnalites actives (souvent GitHub Advanced Security requis pour couverture complete).

### Challenge - Etat d'implementation

- `npm audit --audit-level=high` integre dans CI (job lint).
- Trivy image scan + upload SARIF dans Security Tab.
- gitleaks configure en pre-commit local et en job CI.
- Dependabot configure npm + github-actions en weekly.
- Slack notif differenciee (echec avec cause, succes avec URLs).
- GitHub Deployments API tracee via `bobheadxi/deployments` (staging/prod).
- README complete avec interpretation alertes et procedure CVE critique.
