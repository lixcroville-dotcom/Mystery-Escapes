# Mystery Escape's V8 Online — publicité, classement et lisibilité

## Modifications préparées

- Données de jeu historiques conservées (`user://mystery_escape_save_v2.json`).
- Bouton classement redirigé vers la page **mondiale**. Les records locaux restent séparés.
- Initialisation et chargement AdMob via adaptateur SDK Poing Studios 5.1.x.
- Récompense de 100 pièces, d'un indice ou du double gain quotidien **seulement** après le callback natif `on_user_earned_reward`.
- Interstitielle après 3 enquêtes, avec délai minimal de 5 minutes ; jamais au milieu d'une énigme.
- Messages des fenêtres rendus défilables ; consignes longues déjà défilables.
- Test obligatoire avec les identifiants Google **de test** (aucune annonce commerciale active).

## Ce qui reste à valider

L'environnement de préparation ne dispose ni de Godot ni d'iPhone, et ne peut télécharger les bibliothèques iOS depuis GitHub. Le workflow a été adapté pour installer au build une version officielle du plugin AdMob et un modèle natif pour Godot 4.7.2. **Ce téléchargement, l'export et l'affichage ne sont pas encore validés**. Si cette étape échoue, ne pas présenter l'IPA comme compatible avec les pubs.

Le classement mondial lit Firestore mais aucun serveur anti-triche ne publie actuellement les scores. La base peut rester vide même si l'interface est présente. Ne pas donner au client le droit d'écrire directement un score public.

## À préparer pour la publication officielle

- AdMob : profil de paiement complet, application approuvée, consentement UMP pour EEE/France, configuration âge et déclarations de confidentialité.
- Classements : mécanisme serveur attestant les scores, règles Firestore, quotas, modération des pseudonymes et gestion de suppression de compte.
- iOS : vrai test Godot + SDK + Sideloadly et signature Apple Developer pour App Store Connect.
- Les tests statiques sont distincts des tests d'exécution. Le terme « sans bug » n'est pas garanti.

Documentation officielle : https://poingstudios.github.io/godot-admob-plugin/5.0/
