@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
title Mystery Escape's V4 - Verification
cls
echo =====================================================
echo  MYSTERY ESCAPE'S V4 - CONTROLE DES FICHIERS
 echo =====================================================
set "ERR=0"
for %%F in ("project.godot" "scenes\main_menu.tscn" "scripts\app.gd" "data\levels.json" "data\kids_levels.json" "tools\verify_v4.py" "assets\backgrounds\menu.png" "assets\backgrounds\finalarchive.png" "assets\music\v3\track_01.ogg" "assets\music\v3\track_22.ogg" "assets\ui\apparatus_sliding.png" ".github\workflows\ios-ipa.yml") do (
 if exist "%%~F" (echo [OK] %%~F) else (echo [MANQUANT] %%~F & set "ERR=1")
)
echo.
if "%ERR%"=="0" (
 echo Fichiers principaux presents. Importer project.godot dans Godot 4.7.2.
) else (
 echo Des fichiers manquent. Re-extraire integralement le ZIP.
)
echo Les tests Godot sur iOS ne sont PAS realises par ce script.
pause
