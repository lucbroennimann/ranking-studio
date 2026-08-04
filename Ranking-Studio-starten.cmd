@echo off
title Ranking Studio
setlocal

rem Sucht RankingHelper.ps1 neben dieser Datei oder im Unterordner
rem ranking-helper. So funktioniert dieselbe Datei an beiden Orten.
set "PS=%~dp0RankingHelper.ps1"
if not exist "%PS%" set "PS=%~dp0ranking-helper\RankingHelper.ps1"

if not exist "%PS%" (
  echo.
  echo   RankingHelper.ps1 wurde nicht gefunden.
  echo   Erwartet neben dieser Datei oder in ranking-helper\
  echo.
  echo   Loesung: RankingStudio.html oeffnen, in Box 2 auf
  echo   "Helfer speichern" klicken und beide Dateien in
  echo   denselben Ordner legen wie diese hier.
  echo.
  pause
  exit /b 1
)

rem %* reicht Schalter durch, etwa -NoBrowser fuer den Autostart oder
rem -Port 8790, falls 8787 schon belegt ist.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%" %*
echo.
pause
