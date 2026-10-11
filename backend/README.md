# Backend Firebase – préparation sécurisée

Cette livraison **n’exécute aucun service Firebase en production**. Les classements sont en lecture seule et l’application n’envoie aucun score non vérifié. Les règles Firestore refusent les écritures depuis le client. Pour obtenir des scores réels, il faudra construire et déployer un service sécurisé de validation des parties côté serveur (Firestore Admin SDK et Cloud Functions), gérer les comptes, la suppression de données, les listes d’amis et les saisons.

## Activation après configuration
1. Créer un projet Firebase et y activer Firestore. Sauvegarder le fichier de règles en appliquant et vérifiant les paramètres dans la console. Ne pas déployer aveuglément les règles si le projet contient déjà des données d’autres applications.
2. Renseigner `config/online_services.json` → `firebase.project_id` et `firebase.enabled: true`, `leaderboards.enabled: true` uniquement après publication de classements fiables.
3. Les clés privées du compte de service restent EXCLUSIVEMENT côté serveur. Ne jamais les mettre dans le ZIP, dans Godot, dans GitHub ou dans une conversation.
4. Ne pas créer de vrais documents de scores manuellement en les présentant comme résultats de joueurs réels.

## Publicités
L’adaptateur `AdBridge` est un garde-fou, **pas un SDK AdMob**. Il n’affiche aucune pub et ne donne aucune récompense. L’intégration native nécessite le plugin Mobile Ads compatible avec la version Godot, les identifiants d’application et d’unités publicitaires, le consentement et les tests sur vrais appareils. Utiliser uniquement les unités de test officielles pendant la validation. Ne pas activer la diffusion réelle avant l’examen et la configuration réglementaire.

## Vie privée et autres fonctions
Authentification Apple/Google/e-mail, amis, comptes, nuage, achats et suppression des données restent à implémenter et à auditer. La V8 actuelle fonctionne sans serveur, publicité ni limitation de vies.
