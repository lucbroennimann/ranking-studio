#!/bin/bash
# Ranking Studio - Helfer starten (macOS und Linux)
#
# Gegenstueck zu Ranking-Studio-starten.cmd unter Windows. Sucht
# RankingHelper.ps1 neben dieser Datei oder im Unterordner
# ranking-helper - so funktioniert dieselbe Datei an beiden Orten.

cd "$(dirname "$0")" || exit 1

PS="./RankingHelper.ps1"
[ -f "$PS" ] || PS="./ranking-helper/RankingHelper.ps1"

if [ ! -f "$PS" ]; then
  echo
  echo "  RankingHelper.ps1 wurde nicht gefunden."
  echo "  Erwartet neben dieser Datei oder in ranking-helper/"
  echo
  echo "  Loesung: RankingStudio.html oeffnen, in Box 2 auf"
  echo "  \"Helfer speichern\" klicken und beide Dateien in"
  echo "  denselben Ordner legen wie diese hier."
  echo
  read -n 1 -s -r -p "  Taste zum Beenden"
  exit 1
fi

if ! command -v pwsh >/dev/null 2>&1; then
  echo
  echo "  PowerShell 7 fehlt - ohne sie laeuft der Helfer nicht."
  echo
  echo "  Mit Homebrew:   brew install --cask powershell"
  echo "  Sonst:          https://github.com/PowerShell/PowerShell/releases"
  echo
  echo "  Fuer volle Aufloesung ausserdem empfohlen:"
  echo "                  brew install ffmpeg"
  echo
  read -n 1 -s -r -p "  Taste zum Beenden"
  exit 1
fi

# "$@" reicht Schalter durch, etwa -NoBrowser oder -Port 8790.
pwsh -NoProfile -File "$PS" "$@"

echo
read -n 1 -s -r -p "  Taste zum Beenden"
