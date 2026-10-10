@echo off
setlocal
cd /d "%~dp0"
echo.
echo === Mystery Escape's : verification des fichiers ===
echo.
set "BROKEN=0"
for %%F in ("project.godot" "scenes\main_menu.tscn" "scenes\level_editor_preview.tscn" "scripts\app.gd" "data\levels.json" "assets\backgrounds\menu.png" "assets\sounds\ambient.wav") do (
  if exist "%%~F" (
    echo [OK] %%~F
  ) else (
    echo [MANQUANT] %%~F
    set "BROKEN=1"
  )
)
echo.
if "%BROKEN%"=="0" (
  echo TOUS LES FICHIERS PRINCIPAUX SONT PRESENTS.
  echo Importez project.godot dans Godot 4.
) else (
  echo EXTRACTION INCOMPLETE : clic droit sur le ZIP, puis Extraire tout.
  echo NE PAS importer le ZIP directement dans Godot.
)
echo.
pause
