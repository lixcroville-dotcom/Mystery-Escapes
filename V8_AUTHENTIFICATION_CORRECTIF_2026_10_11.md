# Mystery Escape’s V8 — correctif d’authentification 11/10/2026

## Modifications
- `scripts/online/online_service.gd` : requêtes Auth avec `HTTPRequest.timeout=20`, minuterie de secours, nettoyage centralisé et protection contre les réponses tardives.
- `scripts/app.gd` : les boutons ne relancent plus une requête alors qu’une autre est active.
- Erreurs Firebase explicites (e-mail existant, identifiants invalides, trop de tentatives, erreur réseau).
- Identifiant du package iOS et fichiers de niveaux inchangés.

## Publicités
Les **publicités de test fonctionnent** selon le test utilisateur. La configuration reste en `test_mode=true` : **aucune annonce rémunérée n’est activée** dans cette livraison. Ne pas changer ce paramètre tant que l’application n’est pas examinée, les paiements complétés, la confidentialité et le consentement vérifiés et un essai de diffusion conforme effectué.

## Classement
Les règles Firestore sont déployées et la lecture est opérationnelle selon le retour utilisateur ; les classements restent vides sans backend de publication de scores validés.

## Tests
- `verify_v8.py` : OK, 100 principaux/50 Enfant/522 étapes/0 doublon exact.
- `verify_v8_deep.py` : OK.
- `verify_online_setup.py` : OK ; vérification configuration, **pas** un test live.
- Godot / compilateur iOS / tests iPhone de ce correctif : non exécutés ici.
