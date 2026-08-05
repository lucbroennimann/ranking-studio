# Ranking Studio auf dem Mac einrichten

Ranking Studio ist ein Werkzeug für Ranking-Videos im Hochformat 9:16 —
Top-Listen mit Countdown. Es läuft komplett in deinem Browser, nichts wird
irgendwohin hochgeladen.

**Wenn du nur eigene Videodateien verwenden willst, brauchst du gar keine
Installation.** Dann reicht dieser Link, und du bist fertig:

### → https://lucbroennimann.github.io/ranking-studio/

Videos per Drag & Drop hineinziehen, Titel setzen, exportieren. Läuft
sofort. Nimm dafür **Chrome**, dort funktioniert der Video-Export am besten.

Die folgenden Schritte brauchst du nur, wenn du **YouTube-, TikTok- oder
Instagram-Links** direkt einfügen möchtest. Dafür ist ein kleines
Hilfsprogramm nötig: ein Browser darf von sich aus keine Programme starten
und solche Links nicht laden. Das Hilfsprogramm läuft deshalb daneben, auf
deinem Mac, und reicht die fertige Datei an die Seite durch.

Rechne mit etwa 10 Minuten.

---

## Schritt 1 · PowerShell 7 installieren

Das Hilfsprogramm ist in PowerShell geschrieben. Auf dem Mac fehlt die,
also einmalig nachinstallieren.

**Wenn du Homebrew hast** — im Terminal:

```
brew install --cask powershell
```

**Wenn nicht**, lade den passenden Installer und doppelklicke ihn. Welchen
du brauchst, hängt vom Chip ab: Apfelmenü  → *Über diesen Mac* → Zeile
**Chip** bzw. **Prozessor**.

| Dein Mac | Datei |
| --- | --- |
| Apple M1, M2, M3, M4 … | [powershell-7.6.4-osx-arm64.pkg](https://github.com/PowerShell/PowerShell/releases/download/v7.6.4/powershell-7.6.4-osx-arm64.pkg) (69 MB) |
| Intel | [powershell-7.6.4-osx-x64.pkg](https://github.com/PowerShell/PowerShell/releases/download/v7.6.4/powershell-7.6.4-osx-x64.pkg) (73 MB) |

Der Installer führt dich durch, es sind nur „Weiter"-Klicks.
Neuere Fassungen findest du immer auf der
[Release-Seite von PowerShell](https://github.com/PowerShell/PowerShell/releases/latest).

---

## Schritt 2 · ffmpeg — freiwillig, aber empfohlen

Ohne `ffmpeg` lädt das Hilfsprogramm Videos meist nur bis 720p. Mit
ffmpeg bekommst du die volle Auflösung. Es gibt dafür keinen fertigen
Installer, nur den Weg über Homebrew:

```
brew install ffmpeg
```

Hast du kein Homebrew, überspring das einfach — alles andere funktioniert
trotzdem, die Videos sind nur etwas kleiner.

---

## Schritt 3 · Ranking Studio herunterladen

### → [ZIP herunterladen](https://github.com/lucbroennimann/ranking-studio/archive/refs/heads/main.zip) (37 KB)

Doppelklick auf die geladene Datei entpackt sie. Du bekommst einen Ordner
namens `ranking-studio-main`. Leg ihn irgendwohin, wo du ihn wiederfindest —
der Ort spielt keine Rolle.

---

## Schritt 4 · Der erste Start

Im Ordner liegt **`Ranking-Studio-starten.command`**.

Beim allerersten Mal **nicht** doppelklicken, sondern:

**Rechtsklick auf die Datei → Öffnen → im Hinweisfenster nochmals Öffnen.**

macOS misstraut Dateien aus dem Internet und blockiert den normalen
Doppelklick. Über den Rechtsklick erlaubst du sie einmalig. Ab dem zweiten
Mal genügt der Doppelklick.

> Falls macOS trotzdem blockt: *Systemeinstellungen → Datenschutz &
> Sicherheit*. Dort steht ganz unten ein Hinweis auf die blockierte Datei
> mit einem Knopf **Trotzdem öffnen**.

Es öffnet sich ein Terminal-Fenster. Das Hilfsprogramm fragt:

```
  yt-dlp fehlt. Ohne dieses Programm kann der Helfer keine Links laden.
  Jetzt herunterladen? [J/n]
```

Mit **J** bestätigen und Enter drücken. Es lädt rund 36 MB. Alles landet
nur in deinem Benutzerordner, ohne Administratorrechte und ohne
Systeminstallation:

```
~/Library/Application Support/RankingStudio
```

Zum restlosen Entfernen später reicht es, diesen Ordner zu löschen.

Danach öffnet sich das Studio von selbst im Browser. Oben rechts muss
**Helfer bereit** stehen.

---

## Schritt 5 · Loslegen

1. **Das Terminal-Fenster offen lassen**, solange du arbeitest. Es ist das
   Hilfsprogramm — schliesst du es, sind Links nicht mehr ladbar.
2. Im Studio in Box 2 einen Link in ein Clip-Feld einfügen und auf
   **Laden** klicken. Mehrere Links auf einmal gehen über das grosse Feld
   darunter, einer pro Zeile.
3. Reihenfolge, Design und Timing einstellen, dann **Video exportieren**.
   Der Export läuft in Echtzeit — das Fenster währenddessen offen lassen.

Beenden: Terminal-Fenster schliessen oder `Strg+C` drücken.

**Ab dem zweiten Mal** brauchst du nur noch den Doppelklick auf
`Ranking-Studio-starten.command`. Der Rest ist eingerichtet.

---

## Wenn etwas klemmt

**„… kann nicht geöffnet werden, da es von einem nicht verifizierten
Entwickler stammt."**
Rechtsklick auf die Datei → *Öffnen* → nochmals *Öffnen*. Siehe Schritt 4.

**Der Doppelklick tut gar nichts.**
Öffne das Terminal, tippe `cd ` (mit Leerzeichen dahinter), zieh den
entpackten Ordner ins Terminal-Fenster, drücke Enter. Dann:

```
pwsh -NoProfile -File ranking-helper/RankingHelper.ps1
```

Das umgeht den Doppelklick vollständig und zeigt dir jede Fehlermeldung im
Klartext.

**„pwsh: command not found"**
PowerShell 7 fehlt noch — zurück zu Schritt 1.

**Oben rechts steht „Helfer offline".**
Läuft das Terminal-Fenster noch? Die Seite fragt alle 10 Sekunden von
selbst nach, du musst nichts neu laden.

**Ein Download schlägt fehl.**
Instagram und private Videos verlangen oft eine Anmeldung und gehen dann
nicht. Die genaue Meldung steht im Terminal-Fenster und im Studio unter dem
betroffenen Clip.

**Der Export sieht komisch aus oder fehlt.**
Nimm Chrome. Safaris Videoaufnahme ist wählerischer.

---

## Was auf deinem Mac landet

| Was | Wo | Grösse |
| --- | --- | --- |
| PowerShell 7 | Systemweit, per Installer | ~70 MB |
| yt-dlp | `~/Library/Application Support/RankingStudio/bin` | ~36 MB |
| ffmpeg (freiwillig) | über Homebrew | ~80 MB |
| Geladene Videos | `~/Library/Application Support/RankingStudio/downloads` | wächst mit |
| Ranking Studio selbst | dein entpackter Ordner | 110 KB |

Derselbe Link wird nie zweimal geladen — beim zweiten Mal ist er sofort da.
Den `downloads`-Ordner kannst du jederzeit leeren.

**Es geht nichts nach draussen.** Das Hilfsprogramm ist ausschliesslich
von deinem eigenen Mac aus erreichbar, nicht aus dem WLAN und nicht aus dem
Internet. Deine Videos verlassen deinen Rechner nicht.

---

## Ein Hinweis zum Schluss

Downloads von YouTube und TikTok verstossen gegen deren
Nutzungsbedingungen. Die Entscheidung liegt bei dir.
