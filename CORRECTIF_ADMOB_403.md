# Correction du téléchargement AdMob (11 octobre 2026)

L'échec `HTTP Error 403: rate limit exceeded` provenait de l'appel non authentifié à l'API GitHub dans `tools/install_admob_ci.py`.

Cette livraison utilise désormais les liens directs, versionnés, des fichiers officiels AdMob 5.1.0 :
- `poing-godot-admob-v5.1.0.zip`
- `ios-template-v4.7.2.zip`

Chaque archive est vérifiée via SHA-256 avant extraction, avec les empreintes publiées sur la page officielle du projet. Elle ne nécessite ni token GitHub ni modification des identifiants Firebase/AdMob.

Les vérifications ont porté sur la syntaxe Python du script, le contenu du ZIP et les noms/empreintes publiés. La compilation Godot/Xcode et les annonces sur iPhone ne sont pas vérifiées localement. Si le téléchargement direct renvoie également HTTP 403 ou 429, il faudra utiliser un cache ou fournir les artefacts officiels au workflow, sans désactiver le test des composants natifs.
