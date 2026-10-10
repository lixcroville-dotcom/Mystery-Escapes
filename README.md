# MYSTERY ESCAPE'S — Ultimate Offline Edition (Godot 4)

**50 affaires de détective, 157 étapes, 14 mécanismes interactifs, jeu tactile vertical, FR / EN.**

## Installation sur Windows

1. Décompressez **tout** le ZIP dans un dossier neuf, par exemple `Documents/MysteryEscapesUltimate/`.
2. Lancez Godot **4.3 ou plus récent** (4.7 recommandé).
3. Cliquez **Importer**, puis sélectionnez le **fichier `project.godot`** (ne sélectionnez jamais le ZIP comme paquet Godot).
4. Double-cliquez sur `scenes/main_menu.tscn` pour voir la composition du menu dans l'éditeur.
5. Pressez **F5** pour exécuter le jeu. Si Godot demande une scène principale, choisissez `scenes/main_menu.tscn`.
6. Les dossiers débloquent le suivant après réussite. Les chapitres 2–5 sont disponibles dans les onglets de l'écran DOSSIERS.

Le développement et la sauvegarde fonctionnent **hors ligne**. Les meilleurs scores et le classement sont **locaux à cet appareil**, pas mondiaux.

## Contenu

- 50 enquêtes sur 5 chapitres : Manoir, Laboratoire, Prison, Musée, Horlogerie.
- 157 étapes déterministes réparties en 14 catégories : codes, roulettes, césar, mémoire, fils, preuves, questions, heures, mot secret, engrenages, labyrinthe, objets, sons.
- Mini-histoires indépendantes. Agent Morgan présente chaque étape par un briefing illustré.
- Cadenas, erreurs, effets de transition, son de validation/d'échec, notes musicales, musique ambiante, fonds créés pour le jeu.
- Profil modifiable, XP, pièces, gemmes, collection de thèmes, succès, meilleurs scores, classements locaux, journal, défis quotidiens hors ligne, options FR/EN et audio, sauvegarde JSON.
- 5 arrière-plans 2D stylisés avec une scène de menu illustrée et une scène séparée de prévisualisation.

## Limites importantes

- **Prototype avancé, pas un jeu commercial finalisé** : aucune publicité réelle, aucun achat intégré, aucun serveur/classement mondial et aucune synchronisation cloud. Ajouter ces services exige une intégration et une vérification des règles des stores.
- Les 157 étapes réutilisent **14 modèles de mini-jeux** avec des solutions différentes. Les 50 enquêtes n'ont pas chacune une illustration unique ou un puzzle totalement inédit.
- Les ressources visuelles sont des illustrations vectorielles stylisées générées localement. Il ne s'agit pas d'images 3D ou d'illustrations photoréalistes.
- Les traductions couvrent les écrans et le contenu d'énigmes, mais demanderont une relecture avant publication.
- Il faut ouvrir le jeu dans Godot pour valider et corriger d'éventuelles incompatibilités locales. Le projet n'est pas certifié testé sur iOS/Android.

## Android

Installez **OpenJDK 17**, le SDK Android puis configurez les chemins dans **Éditeur → Paramètres de l'éditeur → Exporter → Android** (suivez la documentation officielle de votre version de Godot). Installez un modèle d'export dans **Éditeur → Gérer les modèles d'exportation**. Sélectionnez Projet → Exporter → Android. Testez l'interface tactile sur plusieurs appareils et configurez signature/permissions avant toute diffusion. L'APK n'est pas fourni ici.

## iOS

L'export iOS natif avec Godot exige un **Mac avec Xcode**, ainsi qu'une configuration Apple Developer pour les distributions publiques. Le projet Godot peut être préparé sur Windows mais l'export final ne peut pas être fait intégralement sur un PC Windows standard.

## Fichiers importants

- `scenes/main_menu.tscn` : scène principale avec aperçu visible dans l'éditeur. Au lancement, le script rend l'UI à partir des données.
- `scenes/level_editor_preview.tscn` : aperçu statique des proportions du briefing et de la zone de jeu (non utilisé par le moteur en exécution).
- `scripts/app.gd` : toute l'interaction et les menus en GDScript.
- `data/levels.json` : définition détaillée des 50 dossiers et solutions ; facile à étendre.
- `assets/backgrounds/` : fonds 2D originaux.
- `assets/sounds/` : effets originaux en WAV.
- Sauvegarde : `user://mystery_escape_save_v2.json`.

## Droits

Les images et sons de ce ZIP ont été produits pour ce projet sans téléchargement de contenus de tiers. Le nom « Mystery Escape's » reste à vérifier quant aux marques et aux noms déjà déposés avant publication.

## Aperçu du menu

`PREVIEW_MENU.png` est une **composition de présentation** réalisée à partir des assets originaux ; ce n'est pas une capture de l'application exécutée dans Godot. Les écrans réels utilisent les composants Godot dessinés par `scripts/app.gd`.

## Astuce de test

Pour consulter le contenu du jeu sans le modifier, ouvrez `data/levels.json`. Pour faire des captures du rendu réel, lancez F5 après import dans Godot. Si une erreur de compilation apparaît, ouvrez **Débogueur → Erreurs** ou **Sortie** et communiquez la première ligne d'erreur : elle permet de corriger précisément une incompatibilité de version.
