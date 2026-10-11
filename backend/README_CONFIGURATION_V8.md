# Mystery Escape’s V8 — Firebase / AdMob configuration

## Réellement intégré dans cette livraison

- Connexion Firebase Authentication via REST Identity Toolkit : invité, inscription et connexion e-mail/mot de passe ; jetons conservés uniquement en mémoire, renouvellement via reconnexion à chaque redémarrage. **Un invité différent est créé à chaque nouvelle connexion** : ne l'utilisez pas encore pour une sauvegarde cloud ou un pseudo permanent.
- L'écran Compte en ligne est accessible depuis le profil et depuis Mondial. La lecture REST des documents Firestore de classements publics est activée, mais les classements seront vides ou interdits (403) tant que les règles et les documents vérifiés ne seront pas déployés.
- Les noms des trois blocs AdMob iOS sont enregistrés dans `config/online_services.json`. Aucun SDK AdMob natif n'est embarqué. **Aucune annonce n'est affichée** et aucune récompense publicitaire n'est donnée.
- L'application reste jouable sans réseau, sans pub obligatoire et sans paiements. La sauvegarde `user://mystery_escape_save_v2.json` est conservée.

## Configuration Firebase restant à effectuer

1. Dans Firebase Console → Firestore → Rules, déployer les règles de `backend/firestore.rules` (la production par défaut refuse généralement toutes les lectures). Ces règles autorisent uniquement la lecture des entrées publiques et refusent toutes les écritures client.
2. Le tableau n'affichera des vrais scores que si un serveur de confiance crée `public_leaderboards/<board>/entries/<id>` avec les champs `display_name` (string) et `score` (integer). **Ne jamais permettre au client de publier arbitrairement des points**.
3. La validation des scores exige un moteur serveur déterministe et une authentification App Check, et ne peut pas être déployée automatiquement sans accès à Firebase. Les Cloud Functions nécessitent généralement le plan Blaze (facturation activée). Ceci reste hors du plan Spark gratuit.
4. Pour les comptes invités durables, ajouter la gestion sécurisée des tokens renouvelés ou un SDK Firebase natif et le rattachement à un compte e-mail ; la version actuelle n'active pas encore le cloud save.

## Publicités

- Identifiants de l'application et des unités stockés dans `config/online_services.json`.
- Activer un plugin natif Google Mobile Ads vérifié compatible avec Godot et iOS, implémenter `AdBridge` pour les callbacks de pub réellement visionnée, configurer le consentement UMP/ATT et tester uniquement avec les IDs de test Google. **Les IDs AdMob personnels ne doivent pas être utilisés pour produire des impressions de test**.
- À la publication, vérifier paiement AdMob, application examinée, app-ads.txt, consentement, politique de confidentialité.
- Stratégie demandée : 100 pièces par pub volontaire, 1 indice, double gain quotidien, au maximum une interstitielle après trois enquêtes ; aucune pendant le jeu ni le chronomètre. Non activé tant que SDK, récompenses validées et consentement ne sont pas opérationnels.

## iOS

- Le `.plist` Firebase est fourni pour référence dans `firebase/GoogleService-Info.plist`. La connexion REST utilise uniquement l'API key publique. **Le fichier n'implique pas l'intégration du SDK Firebase natif**.
- Identifiant iOS conservé : `com.lixcroville.mysteryescapes`.

## Tests et limites

- Exécuter `PYTHONUTF8=1 python tools/verify_v8.py`, `python tools/verify_v8_deep.py` et `python tools/verify_online_setup.py`.
- Puis compiler via GitHub Actions et contrôler le smoke test Godot et le fonctionnement réel sur iPhone. Le CI ne valide ni Firebase à distance, ni la conformité AdMob, ni les interactions tactiles réelles.
