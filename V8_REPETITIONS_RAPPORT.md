# Mystery Escape’s V8 — correction des répétitions et vérification

Date : 10 octobre 2026

## Résultat
- 61 groupes de consignes répétées ont été traités dans les données du jeu.
- 522 étapes recensées : 407 principales, 100 Enfant et 15 Défi Impossible.
- 522 consignes FR distinctes et 522 consignes EN distinctes, pour une comparaison exacte.
- Variantes des séquences de mémoire/sons et mélanges de taquins solvables générés sur les occurrences répétées.
- Les autres types ont reçu des consignes contextualisées. Certaines mécaniques, réponses et configurations restent similaires : **zéro répétition textuelle ne signifie pas zéro répétition de gameplay**.
- `tools/verify_v8.py` : réussi, 0 doublon exact.
- `tools/verify_v8_deep.py` : 522 étapes examinées sur les invariants codés, 0 erreur détectée. Contrôles : tableaux et indices, réponses numériques, chemins des labyrinthes, parité des taquins, séquences et champs obligatoires.
- Les deux contrôles sont exécutés dans le workflow GitHub Actions avant compilation.

## Limitations
- Pas de moteur Godot exécutable disponible ici : pas de test runtime, ni d'exécution réelle de chaque puzzle.
- Pas d'iPhone accessible : impossible de certifier tactile, lisibilité pixel par pixel, audio ou performances.
- Les textes des énigmes de déduction restent parfois directs ; une révision éditoriale manuelle est recommandée.
- Les défis quotidiens utilisent encore 365 sélections parmi 100 dossiers, et non 365 contenus uniques.
- Aucun audit ne garantit absolument l'absence de bugs.

## Compatibilité
- Les IDs de dossiers, le chemin de sauvegarde et l'identifiant iOS sont conservés.
- Les données du jeu ont été modifiées ; tester une sauvegarde iOS réelle avant déploiement large.
