Mystery Escape's V5 - GitHub/iPhone update

1. Extract the UPDATE_GITHUB zip into the ROOT of your existing repository (where project.godot is), overwriting matching files.
2. Git CMD:
   cd /d "C:\Users\lixxc\Documents\MysteryEscapesGitHub"
   git add -A
   git commit -m "Mystery Escape V5 Premium"
   git push origin main
   gh workflow run ios-ipa.yml --ref main
3. Check Actions for a green build. Extract unsigned IPA, install via Sideloadly. DO NOT delete old app first.
4. Test on iPhone: launch logo, music transitions, kids mode, tutorial text and save recovery.

The V5 intro is a short cinematic presentation, not a false progress bar.
