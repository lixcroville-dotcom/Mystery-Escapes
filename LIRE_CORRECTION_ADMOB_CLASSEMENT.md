# Mystery Escape's V8 — correction iPhone du 11 octobre 2026

## Problèmes observés sur iPhone

- `SDK AdMob iOS indisponible : annonce non lancée` : l'adaptateur cherchait `root/MobileAds` (un nœud inexistant) alors que Poing Studios expose `MobileAds` comme classe globale. Le blocage a été retiré.
- `Classement indisponible (HTTP 403)` : Firestore refuse la lecture, probablement parce que les règles livrées n'ont pas encore été déployées. Le ZIP contient désormais `.firebaserc` et `firebase.json` pour faciliter leur publication.

## Installation (projet complet)
Extraire le ZIP à la racine du dépôt Godot. Ensuite `git add -A`, `git commit -m "Fix AdMob singleton check and Firebase deploy"`, `git push origin main` puis lancer le workflow `ios-ipa.yml`.

## Publier les règles Firestore (une fois, depuis Windows)
1. Installer Node.js et exécuter `npm install -g firebase-tools`.
2. Dans le répertoire du projet : `firebase login` (ouvrir le navigateur et confirmer son compte Google).
3. Vérifier le projet : `firebase use mystery-escapes`.
4. Publier les règles et index : `firebase deploy --only firestore`.

Les règles actuelles rendent **publics en lecture seulement** les documents de classement, et interdisent toute écriture depuis l'application. Elles NE créent PAS les scores. Un service d'ingestion sécurisé côté serveur est toujours à construire et nécessite un mode de déploiement compatible avec le budget.

## Limites
- Le projet Godot n'a pas été recompilé dans cet environnement. Le correctif est une correction de logique, à confirmer dans GitHub Actions et sur iPhone.
- Une compilation IPA réussie ne démontre pas que le plugin charge une publicité. Testez les annonces de test officielles de Google en priorité.
- La publication des règles Firebase est une action dans votre compte qui n'a pas été effectuée ici.
- Les scores mondiaux resteront vides sans service de validation et publication de résultats.
