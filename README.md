# Mystery Escape’s V8 — Carnet & Compétition (préproduction)

**LIRE EN PREMIER :** `V8_NOUVELLE_IDENTITE_CLASSEMENT_MONDIAL.md` et `INSTALLER_V8_CARNET_ET_CLASSEMENTS.txt`.

Cette archive contient la V8 complète, avec les enquêtes existantes, le nouvel emblème carnet, 20 avatars, l’XP de profil à attribution unique, la lecture Firestore et le code préparatoire de validation de scores.

La compilation et l’installation sur iPhone n’ont **pas** été refaites ici. Les classements validés par serveur sont désactivés tant que Cloud Functions n’est pas déployé (Firebase Spark ne suffit pas) ; la publicité commerciale reste désactivée jusqu’à approbation AdMob et intégration du consentement. Ne jamais ouvrir les écritures Firestore côté client.

## Tests locaux exécutables

```
python tools/verify_v8.py
python tools/verify_v8_deep.py
python tools/verify_online_setup.py
python tools/verify_v8_release.py
node --test backend/functions/test/*.test.js
```

## Notes techniques et historiques

- Sauvegarde historique : `user://mystery_escape_save_v2.json`.
- Compte Firebase : connexion invité ou e-mail opérationnelle d’après les essais utilisateur sur la version précédente ; non retestée ici.
- Publicités Google de test : affichage et attribution de récompense confirmés par l’utilisateur sur la version précédente ; non retestés sur ce build.
- Aucune facturation, achats réels ou suppression de compte n’a été activée.
- Sous-documentation : `backend/DEPLOIEMENT_SCORES_SANS_TRICHE.md`, `docs/ADMONETISATION_RELEASE_CHECKLIST.md`, `docs/PRIVACY_POLICY_MODELE.md`.

---

## Ancienne documentation (conservée)

# Mystery Escape's — V8 (projet complet pour GitHub)

Cette archive est **autonome** : elle contient `project.godot`, les scenes et scripts, les ressources, les niveaux et `.github/workflows/ios-ipa.yml`. Elle remplace un depot de version plus ancienne, sans necessiter V7 ou un autre correctif V8.

## Installation
Consulte `INSTALLER_SUR_GITHUB_CMD.txt`. Le ZIP doit etre extrait **a la racine** du depot, avec `project.godot` au premier niveau.

## Contenu et limites confirmees
- 100 dossiers principaux et 50 dossiers Enfant; 522 etapes recensees par les verificateurs statiques.
- Correctifs V7 integres a cette version V8.
- Defis quotidiens sur 365 entrees de calendrier (les dossiers sont reutilises, il ne s'agit pas de 365 enigmes exclusives).
- Services en ligne, publicites et achats integres seulement prepares et desactives pour la version de test.
- `python tools/verify_v8.py` et `python tools/verify_v8_deep.py` : controles statiques; pas une certification d'absence de bugs.
- Les tests reels de tactile, d'affichage et de progression sur iPhone restent necessaires.

Les rapports et notes de versions sont inclus pour la tracabilite.
