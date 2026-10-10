# Mystery Escape's V6 — Final Test Edition

## Implémenté

- Accueil simplifié : plus de logo dans la page principale, une grande carte Jouer (nom du dossier), une carte Modes, une carte Défi du jour, succès dans Profil.
- Fond de bureau de détective conservé ; boutons plus espacés ; barre de ressources conservée.
- Nouvelles icônes PNG distinctes : pièce dorée, gemme cyan, vraie roue dentée des paramètres et insigne du profil.
- Défilement tactile vertical explicite dans **Dossiers, Modes, Classement, Journal et Paramètres** avec inertie et barre masquée. Empêche l'ouverture d'un dossier en fin de balayage.
- Nouveau mode **Défi Impossible** : cinq dossiers dont trois enquêtes inédites (15 étapes inédites utilisant des mécaniques existantes), deux dossiers avancés repris de la campagne, 15 minutes partagées, tutoriel en trois étapes, musique de tension en fin de temps.
- Lorsque le temps est écoulé, le joueur peut continuer. **Pénalité de 45 %** sur le score des dossiers terminés après la limite, sans perte de vies.
- Récompenses locales à la fin du Défi Impossible : pièces et gemmes ; enregistrement des records hors ligne ; aucune publicité ni paiement réel.
- Vérification des scripts et des données renforcée dans GitHub Actions (`tools/verify_v4.py`, `tools/verify_v6.py`, import Godot et smoke test avant compilation Xcode).
- Accès « Signaler un problème » dans les paramètres : copie un résumé technique dans le presse-papiers, sans envoyer de données personnelles.
- Identifiant de bundle `com.lixcroville.mysteryescapes` conservé ; chemin de sauvegarde `user://mystery_escape_save_v2.json` conservé ; 100 enquêtes originales et 20 enquêtes Enfant inchangées ; musiques V5 conservées.

## À noter pour les testeurs

- Les 15 nouvelles étapes du mode Impossible réutilisent des mécaniques existantes, avec des indices croisés entre étapes ; il ne s'agit pas de 15 moteurs de puzzles différents.
- Le chronomètre global **s'arrête pendant les fenêtres explicatives** pour laisser lire les consignes.
- Le « classement » demeure strictement local et hors ligne.
- Il faut vérifier le glissement au doigt au milieu d'une carte, les interactions de boutons après un balayage, le comportement audio, la mise en veille/réveil et la conservation des sauvegardes sur l'iPhone 17.
- Aucun test réel dans Godot ou sur iPhone n'a été effectué dans l'environnement de création. Le workflow exécute un smoke test Godot lors de sa prochaine compilation GitHub Actions.
