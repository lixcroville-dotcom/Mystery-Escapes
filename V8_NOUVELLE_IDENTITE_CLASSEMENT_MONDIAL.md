# Mystery Escape's V8 — Carnet & Compétition (préproduction)

**Date :** 11 octobre 2026  
**Base :** dernière V8 dont l'authentification Firebase et les annonces de test ont été validées sur iPhone.  
**Statut :** code et ressources livrables pour essai ; **pas** une version commerciale ni un classement mondial certifié.

## Modifications incluses

- Nouvelle icône iOS de carnet bordeaux et or ; suppression de l'ancien symbole croix-serrure dans l'ouverture et les écrans de conclusion.
- Nouveau fond d'ouverture avec carnet illustré, animation de l'emblème (fondu, mouvement, rotation) et conservation du bouton Passer. Aucun faux chargement en %.
- 20 avatars illustrés distincts, quatre initialement accessibles, puis déblocage par niveau ou pièces. Conservation du champ `avatar` des sauvegardes précédentes.
- Ajout de `avatar_unlocked`, `profile_customization_claimed`, `profile_points` et `profile_public_opt_in` dans les **valeurs par défaut seulement** : les anciennes sauvegardes ne sont pas écrasées.
- Premier équipement de chaque avatar inédit : +25 XP, +10 points de personnalisation, une seule fois par avatar. Un premier changement de pseudo : +25 XP / +10 points une fois. Les équipements suivants ne rapportent rien.
- Classements supplémentaires : Monde, Semaine UTC, Mois UTC, Pays, Amis, Expert, Impossible, Quotidien, Marathon et record du dernier dossier terminé. Pays/Amis restent non opérationnels tant que le serveur associé n'est pas déployé.
- Backend source `backend/functions`: ouverture d'une partie classée, vérification d'une réponse d'étape côté serveur, chronométrage côté serveur, refus de double validation, publication atomique du meilleur score dans les tables Firestore, saisons UTC, visibilité du profil volontaire. Le client classé `scripts/online/ranked_client.gd` est **désactivé** dans la configuration tant que le serveur n'a pas été publié.
- Règles Firestore interdisant aux clients de créer ou de modifier directement des classements.
- AdMob laissé en mode démonstration. Ajout de quatre conditions de sécurité dans le code qui interdisent l'activation commerciale accidentelle sans préparation, consentement et approbation.
- Les scripts de vérification V8 et les tests Node du calcul de score ont été ajoutés à GitHub Actions.

## Configuration conservée

| Sujet | Valeur |
|---|---|
| Firebase | `mystery-escapes` |
| iOS Bundle ID | `com.lixcroville.mysteryescapes` |
| Sauvegarde | `user://mystery_escape_save_v2.json` |
| Enquêtes normales | 100 |
| Enquêtes Enfant | 50 |
| Étapes de toutes les enquêtes | 522 (contrôle de données) |
| Annonces volontaires | 100 pièces ou 1 indice |
| Double récompense | Volontaire, après validation publicitaire |
| Interstitielle | Après 3 enquêtes au plus tôt + délai de 300 secondes |
| AdMob | Identifiants iOS reçus, `test_mode = true` |
| Firebase | Spark, pas de facturation activée ici |
| Classements vérifiés | Code préparé mais **non déployé** |

## Pourquoi tout n'est pas encore en production

**Cloud Functions :** le plan Spark ne permet pas leur déploiement. Ne jamais autoriser les écritures client sur `public_leaderboards` pour contourner ce blocage. Il faudra accepter explicitement Blaze (paiement à l'usage), ou déployer un service de confiance alternatif. Les limites de sécurité du code restent à auditer. Les classements *amis*, l'intégralité de la chaîne Impossible et les performances historiques doivent être complétés avant publication.

**AdMob :** la dernière preuve fournie atteste que les annonces **de test** s'affichent sur iPhone et attribuent la récompense. Elle n'atteste pas que l'application est approuvée pour diffusion rémunérée. Il faut terminer le profil de paiement, publier ou faire réviser l'application suivant les règles Google, configurer app-ads.txt quand requis, recueillir le consentement publicitaire et vérifier la politique de confidentialité. Tant que cela n'est pas fait, `test_mode` doit rester `true`.

**Anti-triche :** le serveur peut refuser les écritures directes et vérifier les réponses, les compteurs, les temps et les nonces. Les réponses sont aussi embarquées dans le jeu hors ligne : un joueur déterminé pourrait les extraire. Un système compétitif fort exigera des énigmes serveur inédites, une attestation App Check et des tests adversariaux supplémentaires. **Aucune solution purement côté client ne garantit zéro triche.**

## Contrôles exécutés dans l'environnement de préparation

- `python tools/verify_v8.py` : réussi.
- `python tools/verify_v8_deep.py` : réussi.
- `python tools/verify_online_setup.py` : réussi.
- `python tools/verify_v8_release.py` : réussi ; 20 images différentes ; source serveur synchronisée ; publicité commerciale désactivée.
- `node --test backend/functions/test/*.test.js` : 5 tests réussis (UTC semaine/mois, calcul des scores, clés des classements, vérification des réponses).
- Vérification de la syntaxe JavaScript serveur : réussie (`node --check`).

**Non effectués ici :** compilation Godot native, compilation Xcode, affichage sur un iPhone, tests de confidentialité/consentement, déploiement Cloud Functions, essai multicomptes du classement, affichage d'une publicité commerciale. Le succès des scripts Python/Node ne prouve pas ces comportements.

## Consignes d'installation

Sur une **copie sauvegardée** de ton dépôt Git, extraire le ZIP complet à la racine. Exécuter les vérificateurs ci-dessus, puis compiler via GitHub Actions. Ne jamais effacer l'application iPhone existante pour installer cette version sans sauvegarde préalable. Les modifications de profil utilisent le même fichier de sauvegarde, mais un test de migration réel reste nécessaire.
