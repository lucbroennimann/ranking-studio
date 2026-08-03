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
| **`Ranking-Studio-starten.cmd` doppelklicken** | startet zusätzlich den Helfer und öffnet das Studio gleich mit |

Videodateien per Drag & Drop funktionieren in allen drei Fällen sofort.
Für **Links** (YouTube, TikTok, Instagram) muss der Helfer laufen — auch
dann, wenn du die gehostete Fassung benutzt: er läuft auf deinem Rechner,
die Seite spricht ihn über `127.0.0.1:8787` an.

## Der Helfer

Ein Browser darf keine Programme starten und kann solche Links nicht selbst
laden: dahinter steckt keine Videodatei, sondern signierte Streamfragmente
ohne CORS-Freigabe. Der Helfer erledigt das deshalb außerhalb des Browsers
per `yt-dlp` und reicht die fertige Datei durch. Alles bleibt lokal.

Einrichten: im Studio in Box 2 auf **Helfer speichern** klicken — es
entstehen `RankingHelper.ps1` und `Ranking-Studio-starten.cmd`. Beide in
denselben Ordner legen, `.cmd` doppelklicken. Beim ersten Mal fragt er, ob
er `yt-dlp` (17 MB) und `ffmpeg` (80 MB) laden darf; beides landet nur in
`%LOCALAPPDATA%\RankingStudio\bin`, ohne Adminrechte und ohne Registry.

## Dateien

```
index.html                    Weiterleitung — Einstiegspunkt für GitHub Pages
RankingStudio.html            das Studio, eigenständig
Ranking-Studio-starten.cmd    startet Helfer + Studio
ranking-helper/
  RankingHelper.ps1           lokaler Server auf 127.0.0.1:8787
  Einbetten.ps1               spielt die Helfer-Dateien in die HTML ein
  LIESMICH.txt                ausführlichere Anleitung zum Helfer
```

## Wartung

Zwei Dinge, die man leicht übersieht:

1. **`RankingHelper.ps1` muss reines ASCII bleiben.** PowerShell 5.1 liest
   `.ps1` ohne BOM als ANSI — Umlaute zerlegen dann den Parser. Für
   `Ranking-Studio-starten.cmd` gilt dasselbe wegen der OEM-Codepage von
   `cmd.exe`. `Einbetten.ps1` prüft beides und bricht sonst ab.
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
