# Mystery Escape's — V3 Enhanced (Godot 4.7.2)

Projet de jeu mobile portrait pour Windows, Android, iPhone.

**Version :** 1.3, build iOS 3. **Pack :** projet Godot + workflow GitHub Actions. **Statut :** contrôles statiques OK ; compilation Godot/iPhone à lancer par l'utilisateur.

## Démarrage PC
1. Extraire entièrement l'archive avec l'Explorateur Windows.
2. Ouvrir `project.godot` dans Godot 4.7.2.
3. Appuyer sur F5. Tester « Modes de jeu », « Paramètres », « TESTER LA MUSIQUE ».

## Mise à jour du dépôt et export IPA
Lire `INSTALLER_SUR_GITHUB_CMD.txt`. L'app iOS utilise toujours `com.lixcroville.mysteryescapes` et le preset cible **iPhone**.

## Audio
Playlist de douze compositions instrumentales stéréo OGG (72 s chacune), total 14 minutes 24 secondes avant répétition au menu, avec playlists alternatives par environnement. Musique 25 %, effets 55 % par défaut. Tester la musique sur iPhone hors mode silence ; si elle n'est toujours pas audible, il faudra relever les logs iOS et vérifier la session audio du système.

## Compatibilité sauvegardes
Chemin `user://mystery_escape_save_v2.json` inchangé, même bundle identifier. Les 50 dossiers et 157 étapes restent identiques. Une version conservée dans un dossier Godot séparé peut être testée avant d'écraser l'ancienne. Ne supprimez pas l'application installée tant que sa sauvegarde n'est pas sécurisée.

## Ce qui reste externe
Pas de vrai classement mondial, ni d'achats et pubs réels sans service backend/SDK/identifiants. Les modes supplémentaires réutilisent les étapes des 50 dossiers ; il n'y a pas de 50 nouvelles histoires. Le fonctionnement exact du nouveau build iOS n'a pas été testé physiquement ici.
