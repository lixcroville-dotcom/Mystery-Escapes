# Mystery Escape's V3 Enhanced — modifications réelles

## Priorité audio et interface
- 12 pistes instrumentales originales composées par synthèse (72 secondes chacune ; 14 min 24 au total). Les pistes se succèdent ; la liste complète se joue au menu.
- Musique adaptée à l'univers ; fond sonore pluie/vent/horloge/feu ; tension avant un compte à rebours ; effets sonores adoucis et limités ; clavier de dialogue plus discret.
- Volumes musique 25 %, bruitages 55 % par défaut ; passage des anciens réglages 70 % vers 55 % sans toucher aux autres sauvegardes ; vibrations désactivées.
- Boutons de test son dans les paramètres. Le bouton test musique réactive explicitement la musique si elle était désactivée.
- Écrans changés sans fond noir transitoire ; animation très légère de déplacement (140 ms) sans fondu à 0.
- Boutons de modes avec icônes originales ; briefing tactile permettant de dévoiler tout le texte.

## Modes jouables à partir des puzzles existants
- Classique (50 dossiers), Détective (5 dossiers liés dans un challenge), Contre-la-montre (75 s par étape), Zen (sans timer), Expert (sans indice et avec limite de temps), Marathon (5 dossiers), Infini (dossiers enchaînés), Défi quotidien (existant).
- Les records des défis restent *locaux*, pas mondiaux. Les modes réutilisent les puzzles existants et ne représentent pas de nouvelles enquêtes scénarisées de A à Z.
- En cas de mise à jour, le système réutilise `user://mystery_escape_save_v2.json` ; mêmes 50 niveaux et 157 étapes inchangés.

## Préparation iPhone
- Même Bundle ID : `com.lixcroville.mysteryescapes`.
- Preset ciblant l'iPhone (`application/targeted_device_family=0`).
- Workflow Mac GitHub Actions avec Xcode 26.3 / Godot 4.7.2 ; IPA non signé prévu pour Sideloadly.

## Limites (non implémentées dans la V3)
- Classement mondial, achats intégrés et publicités réelles : demandent des comptes, un backend, des SDK et la conformité stores.
- Nouvelles mécaniques entièrement inédites de taquin, lasers, puzzles de logique : toujours en projet. Les 14 familles de puzzles existantes sont conservées.
- Les 12 musiques sont des compositions algorithmiques instrumentales simples, pas des enregistrements professionnels.
- La compilation iOS du *nouveau* code et les tests physiques sur iPhone devront être effectués via GitHub et Sideloadly ; ils ne peuvent pas être certifiés localement ici.
