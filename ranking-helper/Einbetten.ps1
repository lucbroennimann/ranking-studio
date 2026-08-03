#requires -version 5.1
<#
  Spielt RankingHelper.ps1 und Ranking-Studio-starten.cmd als Klartext
  in RankingStudio.html ein.

  Immer ausfuehren, nachdem eine der beiden Dateien geaendert wurde -
  sonst laufen Datei und eingebettete Fassung auseinander und der
  Knopf "Helfer speichern" liefert eine veraltete Version aus.

  Gespleisst wird literal ueber IndexOf/Substring, bewusst nicht per
  -replace: der PowerShell-Quelltext steckt voller $-Variablen, die im
  Ersetzungstext als Gruppenverweise gedeutet und stillschweigend
  geleert wuerden.
#>
param(
  [string]$Html = ''
)

$ErrorActionPreference = 'Stop'

if (-not $Html) { $Html = Join-Path (Split-Path $PSScriptRoot -Parent) 'RankingStudio.html' }
if (-not (Test-Path $Html)) { throw "RankingStudio.html nicht gefunden: $Html" }

function Splice([string]$text, [string]$id, [string]$content) {
  $open  = '<script type="text/plain" id="' + $id + '">'
  $close = '</script>'
  $i = $text.IndexOf($open)
  if ($i -lt 0) { throw "Block $id nicht gefunden" }
  $from = $i + $open.Length
  $j = $text.IndexOf($close, $from)
  if ($j -lt 0) { throw "Ende von $id nicht gefunden" }
  return $text.Substring(0, $from) + $content + $text.Substring($j)
}

# Der Starter liegt eine Ebene hoeher, neben RankingStudio.html: dieselbe
# Datei muss auch dort funktionieren, wo der Browser sie hinspeichert.
$ps1 = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'RankingHelper.ps1'), [Text.Encoding]::UTF8)
$cmd = [IO.File]::ReadAllText((Join-Path (Split-Path $PSScriptRoot -Parent) 'Ranking-Studio-starten.cmd'), [Text.Encoding]::UTF8)

$dateien = @(@('RankingHelper.ps1', $ps1), @('Ranking-Studio-starten.cmd', $cmd))

# Beide muessen reines ASCII bleiben: PowerShell 5.1 liest .ps1-Dateien
# ohne BOM als ANSI und cmd.exe .cmd in der OEM-Codepage - Umlaute
# zerlegen dort den Parser bzw. die Ausgabe.
foreach ($paar in $dateien) {
  $n = ($paar[1].ToCharArray() | Where-Object { [int]$_ -gt 127 }).Count
  if ($n -gt 0) { throw "$($paar[0]) enthaelt $n Nicht-ASCII-Zeichen - bitte ersetzen (ae/oe/ue/ss)." }
}

# Ein </script im Inhalt wuerde den Block im Browser vorzeitig beenden.
foreach ($paar in $dateien) {
  if ($paar[1] -match '(?i)</script') { throw "$($paar[0]) enthaelt </script - Abbruch" }
}

$null = [ScriptBlock]::Create($ps1)   # Syntaxpruefung

$t = [IO.File]::ReadAllText($Html, [Text.Encoding]::UTF8)
$t = Splice $t 'src-ps1' $ps1
$t = Splice $t 'src-cmd' $cmd
[IO.File]::WriteAllText($Html, $t, (New-Object Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "  Eingebettet in $Html" -ForegroundColor Green
Write-Host ("  RankingHelper.ps1         : {0:N0} Zeichen" -f $ps1.Length)
Write-Host ("  Ranking-Studio-starten.cmd: {0:N0} Zeichen" -f $cmd.Length)
Write-Host ("  HTML jetzt                : {0:N0} KB" -f ((Get-Item $Html).Length / 1KB))
Write-Host ""
