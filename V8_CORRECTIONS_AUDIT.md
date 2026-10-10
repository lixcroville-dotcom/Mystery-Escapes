# V8 — corrections vérifiées localement

- Correction du mode Enfant : les 50 dossiers sont accessibles depuis le mode, au lieu de seulement 20.
- Correction de la chaîne Impossible : les trois dossiers inédits sont situés après les 50 dossiers Enfant (indices 150–152), et non 120–122.
- Calendrier quotidien : le jeu charge maintenant `data/daily_schedule.json` et l’utilise pour choisir le dossier ; auparavant il ignorait ce fichier.
- Récompense quotidienne : la date du début du défi est conservée dans la session, y compris après reprise, pour éviter qu’un passage à minuit ne change la date de récompense.
- Contrôle périodique de la date locale ; le prochain lancement d’un défi prend la nouvelle date.
- Le vérificateur de CI teste désormais explicitement ces points.

## Limites connues
- Les 365 dates réutilisent les 100 dossiers principaux. Ce ne sont **pas 365 énigmes originales**.
- Les 61 groupes de consignes répétées ont été retravaillés. Voir `V8_REPETITIONS_RAPPORT.md` pour les vérifications et leurs limites.
- En année bissextile, les 365 entrées ne peuvent donner 366 défis distincts ; le dernier jour réutilise une sélection.
- Aucun test Godot runtime, écran réel, tactile iPhone ou audio n’a été réalisé ici.
- Les tests statiques ne prouvent pas que les 522 énigmes sont toutes logiquement résolubles.
- Les fonctions en ligne, achats et pubs restent désactivées en version test.
