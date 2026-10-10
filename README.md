# Mystery Escape's — V4 Ultimate Evolution (build iPhone de test)

**Moteur :** Godot 4.7.2 | **Orientation :** portrait 720×1280 | **Plateformes :** Windows / export iOS via GitHub Actions | **Statut :** vérifications statiques réussies ; compilation/test sur iPhone à effectuer.

## Contenu réellement intégré

- **100 dossiers de campagne, 10 chapitres, 357 étapes principales.** Les 50 dossiers d'origine (et leurs 157 étapes) sont conservés à l'identique, suivis de 50 dossiers supplémentaires et 200 étapes nouvelles, dont 10 taquins coulissants. Les derniers dossiers utilisent des indices logiques et des séquences plus longs ; plusieurs mécaniques restent réutilisées, et non 100 jeux entièrement différents.
- **Mode Enfant :** 10 enquêtes faciles supplémentaires et 20 étapes, séparées des 100 dossiers classiques, avec progression indépendante des déblocages normaux et sans chronomètre. Les anciens modes classiques, Détective, Zen, Expert, Infini, Marathon, Contre-la-montre et Défi quotidien restent disponibles.
- **Musique :** 22 compositions instrumentales stéréo de 72 secondes (~26 min 24 s), choix légèrement aléatoire sans répétition immédiate, playlists selon les environnements, superposition douce et tension de minuterie. La musique du menu continue sans redémarrer entre Accueil, Dossiers, Profil, Classement, Boutique et Paramètres ; elle change uniquement quand on commence une enquête (ou lorsqu'on revient au menu depuis une enquête).
- **Tutoriel :** cinq étapes plus courtes, boutons Passer/Suivant, encadrement des paragraphes, textes adaptés aux limites des panneaux, relecture depuis Paramètres.
- **Paramètres :** barre de défilement latérale masquée, défilement au doigt sur iPhone, réglages musique/effets indépendants (25%/55% sur nouvelle sauvegarde), vibrations désactivées par défaut, taille des textes, réduction des animations, français/anglais.
- **Indices :** **90 pièces** pour le premier niveau d'aide, **150 pièces** pour un indice explicite suivant (ou utilisation du stock acheté en pièces). Pas d'indices publicitaires gratuits dans cette V4 de test.
- **Économie/profil :** système local de pièces, gemmes, scores, avatar, trophées, journal et sauvegarde conservé. Nouvelles images d'ambiance pour les cinq nouveaux chapitres.

## Important : ce qui n'est PAS encore opérationnel

Le questionnaire comporte beaucoup plus de fonctions que ce lot de travail : **le classement mondial**, le serveur et les comptes joueurs, les **publicités**, les **achats intégrés**, les enquêtes entièrement ramifiées à fins alternatives, la reconnaissance de preuves, les véritables rayons laser interactifs, une histoire originale entièrement illustrée pour chaque dossier et toutes les animations de personnages ne sont pas livrés ici. Les emplacements et systèmes locaux restent disponibles, mais ces fonctions demandent un développement supplémentaire. Aucune annonce de « 100 énigmes totalement distinctes » n'est faite.

Ce projet n'a **pas été lancé dans un Godot local ni testé sur un vrai iPhone depuis cet environnement**. Les scripts, les ressources, les solutions, les 100+10 dossiers et l'archive sont validés statiquement. Le workflow GitHub Actions effectue un test Godot puis compile un IPA non signé. Il peut signaler une correction à faire avant installation.

## Installer sous Windows

1. Décompresser le ZIP complet dans un **nouveau dossier** (ne pas utiliser le ZIP directement dans Godot).
2. Importer le fichier `project.godot` dans Godot 4.7.2.
3. Appuyer sur **F5** et tester la musique, le passage entre Accueil / Profil / Boutique / Classement, la liste de 100 dossiers, le tutoriel, le mode Enfant et un taquin.
4. Le projet éditable s'ouvre dans `scenes/main_menu.tscn`, mode **2D** ; les interfaces de jeu sont construites par le script `scripts/app.gd` à l'exécution.

## iOS (GitHub Actions)

Le dépôt conservé est `https://github.com/lixcroville-dotcom/Mystery-Escapes`. Utiliser le paquet de **mise à jour du dépôt** : `MysteryEscapes_V4_UPDATE_GITHUB.zip`, pas le ZIP complet à extraire dans un sous-dossier.

Depuis Windows CMD, dans le dossier local du dépôt :

```
cd /d "C:\Users\lixxc\Documents\MysteryEscapesGitHub"
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%USERPROFILE%\Downloads\MysteryEscapes_V4_UPDATE_GITHUB.zip' -DestinationPath '%CD%' -Force"
python tools\verify_v4.py
git status
git add -A
git commit -m "Mystery Escapes V4 - audio, tutoriels, 100 dossiers et mode enfant"
git push origin main
gh workflow run ios-ipa.yml --ref main
```

Si Python n'est pas disponible localement, ignorer uniquement `python tools\verify_v4.py` : ce contrôle sera exécuté par GitHub Actions.

Consulter `https://github.com/lixcroville-dotcom/Mystery-Escapes/actions`. Dans l'exécution verte, télécharger l'artifact **MysteryEscapes-V4-IPA-non-signe**, extraire son `.ipa`, puis le signer/installer via Sideloadly.

**Ne supprimer ni l'application actuellement installée, ni son dossier de données**. Le bundle ID reste `com.lixcroville.mysteryescapes` et le fichier de sauvegarde `user://mystery_escape_save_v2.json` est inchangé. Une copie `.bak` des sauvegardes locales est maintenant faite au moment des mises à jour. La compatibilité de la mise à jour sur ton iPhone ne sera confirmée qu'après l'installation. Fais une sauvegarde de l'iPhone auparavant si possible.

## Tester en priorité

1. Démarrer une playlist en menu, ouvrir Profil/Classement/Boutique : la musique doit **continuer sans repartir de zéro**.
2. Démarrer un nouveau dossier : la musique doit changer avec une transition douce ; retourner dans le menu.
3. Paramètres : faire défiler **en glissant le doigt au milieu du contenu** ; modifier les volumes sans redémarrage de la musique.
4. Rejouer le tutoriel en français et anglais : aucune phrase ne doit sortir du panneau.
5. Terminer une enquête classique puis commencer le mode Enfant ; vérifier que le déblocage de la campagne principale n'est pas modifié.
6. Débloquer progressivement les dossiers 51–100 et tester un taquin (dossier 51, deuxième étape).
7. Fermer/réouvrir l'application : vérifier la sauvegarde existante, les pièces et les meilleurs scores.

Sur iOS, les fonctions audio peuvent dépendre du mode Silence, de la session audio et du matériel. Tester avec et sans écouteurs, et à faible volume initial. Aucun résultat de test sur haut-parleur iPhone n'est revendiqué ici.
