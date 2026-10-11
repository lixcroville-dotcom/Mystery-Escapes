# Classements mondiaux — ce qu'il faut déployer (et ce qui reste à faire)

## État actuel

- Comptes Firebase invités et e-mail : **confirmés par le testeur sur iPhone dans la V8 précédente**.
- Consultation du classement Firestore : confirmée (réponse vide plutôt que HTTP 403).
- Les règles Firestore précédentes ont été publiées par l'utilisateur, et la nouvelle version ajoute des chemins de lecture pour les périodes UTC et les pays.
- **Aucun service de publication de scores n'est déployé** à la date du présent rapport.
- Sur Firebase **Spark**, Cloud Functions exige un passage au plan Blaze. Il n'y a pas de code côté iPhone permettant de contourner ce prérequis de façon sécurisée.

## Structure de la future API serveur

Source : `backend/functions/index.js` (Node.js 22, Firebase Functions v2, Admin SDK).

1. `startRankedRun` ouvre une tentative pour un joueur authentifié et un dossier déterminé ; le serveur choisit le début de chronomètre.
2. `requestRankedHint` enregistre le recours à un indice sur le serveur.
3. `submitRankedStage` vérifie les réponses à partir de `levels_ranked.json` embarqué dans les fonctions, refuse les soumissions trop rapides ou rejouées, calcule le score sans se fier aux points envoyés par le téléphone, puis écrit le meilleur score.
4. `setPublicRankProfile` définit pseudo, pays et visibilité du classement. La visibilité est une action volontaire : pas de publication automatique de compte invité.
5. Chaque écriture de score est réalisée en transaction Admin SDK. Le client ne détient aucune clé privée et les règles Firestore interdisent la création de score côté mobile.

**Limites connues AVANT mise en production :** les cinq dossiers du Défi Impossible ne sont pas encore validés comme une chaîne unique ; le classement entre amis et le code ami n'ont pas de vérificateur serveur ; les performances chronométrées hors ligne ne peuvent pas être certifiées a posteriori ; l'identité des pseudos n'est pas encore unique à l'échelle mondiale ; il faut ajouter suppression de compte, politique de conservation, App Check, limitation avancée des abus et tests Emulator Suite. Il serait incorrect de qualifier cette source de « classement 100 % terminé ».

## Quand tu choisiras d'activer une plateforme de serveur

**Option A — Firebase Blaze :** après approbation explicite du propriétaire, configurer la facturation et des alertes. Puis installer Node 22/npm, faire `cd backend/functions && npm install && npm test`, revenir à la racine et exécuter `firebase deploy --only functions:ranking,firestore` seulement après revue des règles et tests Firebase Emulator. Modifier ensuite `leaderboards.server_validation_deployed` en `true`, reconstruire l'IPA et vérifier sur deux comptes. Les alertes de coût ne sont pas un plafonnement garanti.

**Option B — rester Spark gratuit :** conserver les classements en lecture seule et utiliser un service externe de confiance hébergé gratuitement avec son propre contrôle d'identité et de score (non fourni/déployé actuellement). Ne pas remplacer le serveur par des écritures ouvertes directement depuis Godot.

## Validation indispensable avant publication

Tester avec deux comptes distincts : authentification, création de tentative, résolution réelle d'une enquête, rejet d'un score fabriqué, impossibilité de réutiliser une tentative, prise en compte des indices, meilleur score, apparition mondiale, passage lundi 00:00 UTC et premier jour du mois, pays choisi, confidentialité des comptes invités et révocation après suppression du compte.
