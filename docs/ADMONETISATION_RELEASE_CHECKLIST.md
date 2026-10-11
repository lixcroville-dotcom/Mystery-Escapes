# Checklist AdMob — passage du mode test aux vraies annonces

## Faits vérifiés

- Sur l'iPhone du testeur : une annonce Google de test s'est affichée et la récompense a été accordée.
- IDs fournis : app AdMob iOS et trois unités (pièces, indices, interstitielle) ; ils sont conservés dans `config/online_services.json`.
- `ads.test_mode` est **true** et `ads.production_approved` est **false**.

## Conditions non encore confirmées / bloquantes

1. Profil de paiement AdMob : encore déclaré incomplet.
2. État de l'application : utilisateur a répondu « inconnu » ; l'approbation Google n'est pas attestée.
3. Application pas encore publiée sur l'App Store (Apple Developer non souscrit selon le questionnaire).
4. Contrôle AdMob app-ads.txt : vérifier les exigences de la console, et mettre en place un site développeur lié à la fiche de l'application.
5. Consentement publicitaire européen : intégrer et tester l'interface UMP native pour les utilisateurs pertinents ; l'application n'a pas encore de politique de confidentialité publiée ni de mécanisme de suppression du compte.
6. Vérifier ATT/identifiants iOS et libellés de confidentialité App Store applicables.

**Ne pas** basculer `test_mode` à `false` en se contentant de renseigner des flags. Le code actuel bloque volontairement le mode commercial non préparé. En production, tester les annonces sur des appareils explicitement marqués comme test auprès d'AdMob ; ne pas visionner des annonces réelles pour générer artificiellement des impressions.

Les montants de récompense restent les choix du questionnaire : 100 pièces, 1 indice, doublement des gains quotidiens, et interstitielle jamais pendant une énigme / minuteur, après au moins 3 enquêtes et 300 s d'intervalle. Les achats « Sans pubs » restent **désactivés**, en préparation seulement.
