# Mystery Escape's V6 — Final Test Edition

Projet Godot 4.7.2, portrait 720×1280, export iOS via GitHub Actions. Les publicités, achats in-app et classements mondiaux sont désactivés.

## Deux fichiers de livraison

- `MysteryEscapes_V6_UPDATE_GITHUB.zip` : **extraire PAR-DESSUS les fichiers de ton projet V5**, à la racine du dépôt GitHub, sans effacer les autres dossiers.
- `MysteryEscapes_V6_PROJET_COMPLET.zip` : projet Godot autonome V6. Importer `project.godot` après décompression.

### Mise à jour CMD (Windows)

```cmd
cd /d "C:\Users\lixxc\Documents\MysteryEscapesGitHub"
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%USERPROFILE%\Downloads\MysteryEscapes_V6_UPDATE_GITHUB.zip' -DestinationPath '%CD%' -Force"
python tools/verify_v4.py
python tools/verify_v6.py
git status --short
git add -A
git commit -m "Mystery Escapes V6 Final Test"
git push origin main
gh workflow run ios-ipa.yml --ref main
```

Le workflow sur https://github.com/lixcroville-dotcom/Mystery-Escapes/actions utilisera Godot 4.7.2 et Xcode 26.3, exécutera les vérifications, puis publiera `MysteryEscapes-V6-IPA-non-signe` si la compilation réussit.

### Installation sur iPhone

Avec Sideloadly : télécharger le nouvel Artifact GitHub, extraire le `.ipa`, signer et installer sur le même iPhone. **Ne pas supprimer l'application existante** (même Bundle ID / même chemin de sauvegarde). Sauvegarder l'iPhone avant toute mise à jour importante.

### Essais conseillés

1. Accueil : trois espaces clairs et réglages avec engrenage ; pictogrammes pièces / gemmes distincts.
2. Dossiers : ouvrir une carte, glisser du centre vers le haut (le contenu monte), puis toucher une carte sans fausse ouverture pendant le balayage.
3. Modes : faire défiler jusqu'au Défi Impossible, appuyer sur Jouer. Lire les instructions.
4. Défi Impossible : résoudre les étapes, vérifier que le chronomètre global survit au changement de dossier et à la reprise d'une sauvegarde.
5. Tester après quinze minutes : temps écoulé -> continuer possible et pénalité de 45 % sur les scores suivants.
6. Classement, journal, paramètres : faire défiler directement avec le doigt.
7. Tester veille/réveil, sons au haut-parleur, sauvegarde locale et changement d'orientation iOS.

Tests automatisés : données, chemins, assets, code statique, import Godot + smoke test GitHub Actions. Le **comportement tactile physique, la signature et l'expérience audio** doivent être validés par les testeurs iPhone.
