# Ranking Studio

**→ [Studio öffnen](https://lucbroennimann.github.io/ranking-studio/)**

Werkzeug für Ranking-Videos im Hochformat 9:16 — Top-Listen mit Countdown.
Alles läuft im Browser: Vorschau und Export sind derselbe Canvas
(1080×1920), aufgezeichnet in Echtzeit mit `MediaRecorder`. Kein Upload,
keine CDN, keine Abhängigkeiten — eine einzelne HTML-Datei.

## Öffnen

| Weg | Was du brauchst |
| --- | --- |
| **[lucbroennimann.github.io/ranking-studio](https://lucbroennimann.github.io/ranking-studio/)** | nur den Link — läuft auf jedem Rechner |
| **`RankingStudio.html` doppelklicken** | den Ordner lokal |
| **`Ranking-Studio-starten.cmd`** (Windows) bzw. **`.command`** (macOS, Linux) | startet zusätzlich den Helfer und öffnet das Studio gleich mit |

Videodateien per Drag & Drop funktionieren in allen drei Fällen sofort.
Für **Links** (YouTube, TikTok, Instagram) muss der Helfer laufen — auch
dann, wenn du die gehostete Fassung benutzt: er läuft auf deinem Rechner,
die Seite spricht ihn über `127.0.0.1:8787` an.

## Der Helfer

Ein Browser darf keine Programme starten und kann solche Links nicht selbst
laden: dahinter steckt keine Videodatei, sondern signierte Streamfragmente
ohne CORS-Freigabe. Der Helfer erledigt das deshalb außerhalb des Browsers
per `yt-dlp` und reicht die fertige Datei durch. Alles bleibt lokal.

Er läuft unter **Windows, macOS und Linux** — bewusst als eine einzige
Datei, zwei Fassungen wären nach der ersten Änderung auseinandergelaufen.
Nur die Starter sind getrennt, weil `.cmd` und `bash` sich nicht vertragen.

**Einrichten, Windows:** ZIP entpacken, `Ranking-Studio-starten.cmd`
doppelklicken. Beim ersten Mal fragt er, ob er `yt-dlp` (17 MB) und
`ffmpeg` (80 MB) laden darf; beides landet nur in
`%LOCALAPPDATA%\RankingStudio\bin`, ohne Adminrechte und ohne Registry.

**Einrichten, macOS:** einmalig
[PowerShell 7](https://github.com/PowerShell/PowerShell/releases)
installieren — `brew install --cask powershell`. Für volle Auflösung
zusätzlich `brew install ffmpeg`; ohne ffmpeg lädt yt-dlp meist nur bis
720p. Dann `Ranking-Studio-starten.command` doppelklicken. Kommt die Datei
nicht aus dem ZIP, sondern über **Helfer speichern**, fehlt ihr das
Ausführungsrecht — einmalig im Terminal:

```
chmod +x Ranking-Studio-starten.command
```

`yt-dlp` holt er sich selbst (36 MB), abgelegt unter
`~/Library/Application Support/RankingStudio/bin`.

## Dateien

```
index.html                      Weiterleitung — Einstiegspunkt für GitHub Pages
RankingStudio.html              das Studio, eigenständig
Ranking-Studio-starten.cmd      startet Helfer + Studio (Windows)
Ranking-Studio-starten.command  dasselbe für macOS und Linux
ranking-helper/
  RankingHelper.ps1             lokaler Server auf 127.0.0.1:8787, alle Systeme
  Einbetten.ps1                 spielt die drei Dateien in die HTML ein
  LIESMICH.txt                  ausführlichere Anleitung zum Helfer
```

## Wartung

Zwei Dinge, die man leicht übersieht:

1. **Alle drei Dateien müssen reines ASCII bleiben.** PowerShell 5.1 liest
   `.ps1` ohne BOM als ANSI, `cmd.exe` liest `.cmd` in der OEM-Codepage,
   und ein bash-Skript hängt an der Locale des fremden Rechners — Umlaute
   zerlegen dort Parser oder Ausgabe. `Einbetten.ps1` prüft das und bricht
   sonst ab. Die Zeilenenden nagelt `.gitattributes` fest: `.command`
   braucht reine LF, sonst stolpert bash über das `\r`.
2. **Helfer und HTML dürfen nicht auseinanderlaufen.** Der Helfer steckt
   als Klartext-Kopie in `RankingStudio.html` (`<script type="text/plain">`),
   damit der Knopf „Helfer speichern" ohne weiteren Download auskommt. Nach
   jeder Änderung am Helfer:

   ```
   powershell -ExecutionPolicy Bypass -File ranking-helper\Einbetten.ps1
   ```

## Hinweis

Downloads von YouTube und TikTok verstoßen gegen deren Nutzungsbedingungen.
Die Entscheidung liegt bei dir.
