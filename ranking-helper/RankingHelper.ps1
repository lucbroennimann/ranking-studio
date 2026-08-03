#requires -version 5.1
<#
  Ranking Studio - lokaler Helfer
  ---------------------------------------------------------------
  Ein Browser darf keine Programme starten. Dieser Helfer laeuft
  deshalb ausserhalb des Browsers, laedt Video-Links per yt-dlp
  und reicht die fertige Datei an das Studio durch.

  Alles bleibt auf diesem Rechner. Es wird nichts hochgeladen.
  Beenden mit Strg+C oder Fenster schliessen.

  Aufrufe:
    RankingHelper.ps1                 normaler Start
    RankingHelper.ps1 -Setup          yt-dlp und ffmpeg aktualisieren
    RankingHelper.ps1 -Port 8790      anderer Port
#>
param(
  [int]$Port = 8787,
  [string]$Html = '',
  [switch]$Setup,
  [switch]$NoBrowser,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$VERSION = '1.1'

$YTDLP_URL  = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
$FFMPEG_URL = 'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip'

# ---------------------------------------------------------------- Pfade
$Root    = Join-Path $env:LOCALAPPDATA 'RankingStudio'
$BinDir  = Join-Path $Root 'bin'
$DownDir = Join-Path $Root 'downloads'
$MemoPth = Join-Path $Root 'html-pfad.txt'
New-Item -ItemType Directory -Force -Path $BinDir  | Out-Null
New-Item -ItemType Directory -Force -Path $DownDir | Out-Null

function Find-Tool([string]$name) {
  $local = Join-Path $BinDir "$name.exe"
  if (Test-Path $local) { return $local }
  $cmd = Get-Command "$name.exe" -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Find-Html {
  $cands = @()
  if ($Html) { $cands += $Html }
  $cands += (Join-Path $PSScriptRoot 'RankingStudio.html')
  $cands += (Join-Path (Split-Path $PSScriptRoot -Parent) 'RankingStudio.html')
  $cands += (Join-Path $env:USERPROFILE 'Downloads\RankingStudio.html')
  if (Test-Path $MemoPth) {
    try { $cands += ([IO.File]::ReadAllText($MemoPth)).Trim() } catch { }
  }
  foreach ($c in $cands) {
    if ($c -and (Test-Path $c)) {
      try { [IO.File]::WriteAllText($MemoPth, $c) } catch { }
      return $c
    }
  }
  return $null
}

# ---------------------------------------------------------------- Setup
function Confirm-Yes([string]$frage) {
  if ($Yes) { return $true }
  if (-not [Environment]::UserInteractive) { return $false }
  $a = Read-Host ("  " + $frage + " [J/n]")
  return ($a -eq '' -or $a -match '^[jJyY]')
}

function Install-Ytdlp {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Write-Host "  yt-dlp wird geladen (ca. 17 MB) ..." -ForegroundColor Cyan
  Write-Host "  Quelle: $YTDLP_URL" -ForegroundColor DarkGray
  Invoke-WebRequest -Uri $YTDLP_URL -OutFile (Join-Path $BinDir 'yt-dlp.exe') -UseBasicParsing
  Write-Host "  yt-dlp fertig." -ForegroundColor Green
}

function Install-Ffmpeg {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Write-Host "  ffmpeg wird geladen (ca. 80 MB, dauert einen Moment) ..." -ForegroundColor Cyan
  Write-Host "  Quelle: $FFMPEG_URL" -ForegroundColor DarkGray
  $zip = Join-Path $env:TEMP 'rs-ffmpeg.zip'
  $tmp = Join-Path $env:TEMP 'rs-ffmpeg'
  Invoke-WebRequest -Uri $FFMPEG_URL -OutFile $zip -UseBasicParsing
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
  foreach ($exe in @('ffmpeg.exe', 'ffprobe.exe')) {
    $f = Get-ChildItem -Path $tmp -Filter $exe -Recurse -File | Select-Object -First 1
    if ($f) { Copy-Item $f.FullName -Destination (Join-Path $BinDir $exe) -Force }
  }
  Remove-Item $zip -Force -ErrorAction SilentlyContinue
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "  ffmpeg fertig." -ForegroundColor Green
}

function Ensure-Tools {
  if ($Setup) {
    Write-Host ""
    Write-Host "  Aktualisiere Werkzeuge ..." -ForegroundColor Cyan
    try { Install-Ytdlp }  catch { Write-Host "  yt-dlp FEHLER: $($_.Exception.Message)" -ForegroundColor Red }
    try { Install-Ffmpeg } catch { Write-Host "  ffmpeg FEHLER: $($_.Exception.Message)" -ForegroundColor Red }
    return
  }
  if (-not (Find-Tool 'yt-dlp')) {
    Write-Host ""
    Write-Host "  yt-dlp fehlt. Ohne dieses Programm kann der Helfer keine Links laden." -ForegroundColor Yellow
    Write-Host "  Es kommt vom offiziellen Projekt und landet nur in:" -ForegroundColor DarkGray
    Write-Host "  $BinDir" -ForegroundColor DarkGray
    if (Confirm-Yes 'Jetzt herunterladen?') {
      try { Install-Ytdlp } catch { Write-Host "  FEHLER: $($_.Exception.Message)" -ForegroundColor Red }
    } else {
      Write-Host "  Uebersprungen. Das Studio funktioniert weiter mit Dateien statt Links." -ForegroundColor DarkGray
    }
  }
  if ((Find-Tool 'yt-dlp') -and -not (Find-Tool 'ffmpeg')) {
    Write-Host ""
    Write-Host "  ffmpeg fehlt. Ohne ffmpeg laedt yt-dlp meist nur bis 720p." -ForegroundColor Yellow
    if (Confirm-Yes 'ffmpeg ebenfalls laden? (ca. 80 MB)') {
      try { Install-Ffmpeg } catch { Write-Host "  FEHLER: $($_.Exception.Message)" -ForegroundColor Red }
    } else {
      Write-Host "  Uebersprungen. Spaeter nachholbar mit: RankingHelper.ps1 -Setup" -ForegroundColor DarkGray
    }
  }
}

# ---------------------------------------------------------------- HTTP-Helfer
function Add-Cors($res) {
  $res.Headers['Access-Control-Allow-Origin']          = '*'
  $res.Headers['Access-Control-Allow-Headers']         = 'Content-Type'
  $res.Headers['Access-Control-Allow-Methods']         = 'GET,POST,OPTIONS'
  $res.Headers['Access-Control-Allow-Private-Network'] = 'true'
  $res.Headers['Cache-Control']                        = 'no-store'
}

function Send-Bytes($ctx, [byte[]]$bytes, [string]$type, [int]$code) {
  $res = $ctx.Response
  $res.StatusCode      = $code
  $res.ContentType     = $type
  $res.ContentLength64 = $bytes.Length
  Add-Cors $res
  $res.OutputStream.Write($bytes, 0, $bytes.Length)
  $res.OutputStream.Close()
}

function Send-Json($ctx, $obj, [int]$code = 200) {
  $json = $obj | ConvertTo-Json -Depth 6 -Compress
  Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes($json)) 'application/json; charset=utf-8' $code
}

function Read-Body($ctx) {
  $sr = New-Object IO.StreamReader($ctx.Request.InputStream, [Text.Encoding]::UTF8)
  $txt = $sr.ReadToEnd(); $sr.Close()
  if ([string]::IsNullOrWhiteSpace($txt)) { return $null }
  try { return $txt | ConvertFrom-Json } catch { return $null }
}

# ---------------------------------------------------------------- Jobs
$script:jobs = @{}

function Get-JobId([string]$url) {
  $sha = [Security.Cryptography.SHA1]::Create()
  $h = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($url.Trim()))
  $hex = ($h | ForEach-Object { $_.ToString('x2') }) -join ''
  return 'v' + $hex.Substring(0, 12)
}

function Get-MediaFile([string]$id) {
  Get-ChildItem -Path $DownDir -Filter "$id.*" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -match '^\.(mp4|webm|mkv|mov|m4v)$' } |
    Sort-Object Length -Descending | Select-Object -First 1
}

function Read-LogTail([string]$path, [int]$n = 10) {
  if (-not (Test-Path $path)) { return @() }
  try {
    $fs = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    $sr = New-Object IO.StreamReader($fs)
    $all = $sr.ReadToEnd(); $sr.Close(); $fs.Close()
    $lines = @($all -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
    if ($lines.Count -gt $n) { return $lines[($lines.Count - $n)..($lines.Count - 1)] }
    return $lines
  } catch { return @() }
}

function Get-JobProgress([string]$log) {
  $lines = Read-LogTail $log 12
  for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match '\[download\]\s+([\d.]+)%') { return [double]$Matches[1] }
  }
  return 0
}

function Get-JobTitle([string]$id) {
  $j = Join-Path $DownDir "$id.info.json"
  if (Test-Path $j) {
    try { return (Get-Content -LiteralPath $j -Raw -Encoding UTF8 | ConvertFrom-Json).title } catch { }
  }
  return $null
}

function Start-Fetch([string]$url, [string]$id) {
  $ytdlp = Find-Tool 'yt-dlp'
  if (-not $ytdlp) { throw 'yt-dlp fehlt. Helfer neu starten und die Frage mit J beantworten.' }
  $ffmpeg = Find-Tool 'ffmpeg'

  Get-ChildItem -Path $DownDir -Filter "$id.*" -File -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

  $log    = Join-Path $DownDir "$id.log"
  $errLog = $log + '.err'
  $out    = Join-Path $DownDir "$id.%(ext)s"

  $a = @('--no-playlist', '--no-part', '--newline', '--no-mtime',
         '--write-info-json', '--retries', '3', '-o', $out)
  if ($ffmpeg) {
    $a += @('--ffmpeg-location', (Split-Path $ffmpeg -Parent),
            '-f', 'bv*[height<=1080]+ba/b[height<=1080]/bv*+ba/b',
            '--merge-output-format', 'mp4')
  } else {
    $a += @('-f', 'b[ext=mp4]/b')
  }
  $a += $url

  $p = Start-Process -FilePath $ytdlp -ArgumentList $a -NoNewWindow -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError $errLog

  $script:jobs[$id] = @{ proc = $p; log = $log; err = $errLog; url = $url; started = Get-Date }
  Write-Host ("  -> yt-dlp gestartet (PID {0})" -f $p.Id) -ForegroundColor DarkGray
}

function Get-JobState([string]$id) {
  $file = Get-MediaFile $id
  $job  = $script:jobs[$id]

  if (-not $job) {
    if ($file) { return @{ state = 'done'; progress = 100; title = (Get-JobTitle $id); size = $file.Length } }
    return @{ state = 'unknown'; progress = 0 }
  }

  if (-not $job.proc.HasExited) {
    return @{ state = 'running'; progress = (Get-JobProgress $job.log); title = (Get-JobTitle $id) }
  }

  if ($file) { return @{ state = 'done'; progress = 100; title = (Get-JobTitle $id); size = $file.Length } }

  $tail = @(Read-LogTail $job.err 6) + @(Read-LogTail $job.log 6)
  $msg  = ($tail | Where-Object { $_ -match 'ERROR|Unsupported|Unable|HTTP Error' } | Select-Object -Last 1)
  if (-not $msg) { $msg = ($tail | Select-Object -Last 1) }
  if (-not $msg) { $msg = 'Download fehlgeschlagen.' }
  return @{ state = 'error'; progress = 0; error = [string]$msg }
}

# ---------------------------------------------------------------- Start
Write-Host ""
Write-Host "  RANKING STUDIO - Helfer" -ForegroundColor Green
Write-Host "  ---------------------------------------------"

$base = "http://127.0.0.1:$Port/"

# Laeuft schon einer? Dann nicht doppelt starten, nur Browser oeffnen.
function Test-Running([int]$p) {
  try {
    $r = Invoke-RestMethod ("http://127.0.0.1:{0}/health" -f $p) -TimeoutSec 2
    return [bool]$r.ok
  } catch { return $false }
}

if (Test-Running $Port) {
  Write-Host ""
  Write-Host "  Der Helfer laeuft bereits - es wird nur das Studio geoeffnet." -ForegroundColor Green
  Write-Host "  $base"
  Write-Host ""
  if (-not $NoBrowser) { Start-Process $base | Out-Null }
  Start-Sleep -Seconds 2
  exit 0
}

Ensure-Tools

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
try { $listener.Start() }
catch {
  Write-Host ""
  Write-Host "  Port $Port ist belegt - laeuft der Helfer vielleicht schon?" -ForegroundColor Yellow
  Write-Host "  Anderer Port:  RankingHelper.ps1 -Port 8790"
  Write-Host ""
  Read-Host "Enter zum Beenden"; exit 1
}

$HtmlPath = Find-Html
$ytdlp    = Find-Tool 'yt-dlp'
$ffmpeg   = Find-Tool 'ffmpeg'

$FALLBACK = @"
<!doctype html><meta charset="utf-8"><title>Ranking-Helfer</title>
<body style="background:#05070f;color:#e8eef9;font-family:Segoe UI,system-ui,sans-serif;padding:44px;line-height:1.7">
<h1 style="color:#34d399">Helfer laeuft</h1>
<p>Die Datei <b>RankingStudio.html</b> liegt nicht neben diesem Skript und wurde auch sonst nicht gefunden.</p>
<p>Das ist kein Problem: oeffne <b>RankingStudio.html</b> einfach per Doppelklick.
Die Seite findet den Helfer von selbst und zeigt oben rechts <b>Helfer bereit</b>.</p>
<p style="color:#8b9bba">Soll die Seite auch von hier kommen, lege RankingStudio.html neben RankingHelper.ps1 und starte neu.</p>
</body>
"@

Write-Host ""
Write-Host "  ---------------------------------------------"
Write-Host "  Adresse   : $base"
Write-Host ("  yt-dlp    : {0}" -f $(if ($ytdlp)  { 'bereit' } else { 'fehlt - Link-Import inaktiv' }))
Write-Host ("  ffmpeg    : {0}" -f $(if ($ffmpeg) { 'bereit' } else { 'fehlt - meist nur bis 720p' }))
Write-Host ("  Downloads : {0}" -f $DownDir)
Write-Host ("  Studio    : {0}" -f $(if ($HtmlPath) { $HtmlPath } else { 'nicht gefunden - HTML einfach direkt oeffnen' }))
Write-Host "  ---------------------------------------------"
Write-Host "  Fenster offen lassen. Beenden mit Strg+C." -ForegroundColor DarkGray
Write-Host ""

if (-not $NoBrowser -and $HtmlPath) { Start-Process $base | Out-Null }

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
      $req  = $ctx.Request
      $path = $req.Url.AbsolutePath.TrimEnd('/')
      if ($path -eq '') { $path = '/' }

      if ($req.HttpMethod -eq 'OPTIONS') {
        Add-Cors $ctx.Response
        $ctx.Response.StatusCode = 204
        $ctx.Response.Close()
        continue
      }

      switch ($path) {

        '/' {
          if ($HtmlPath -and (Test-Path $HtmlPath)) {
            Send-Bytes $ctx ([IO.File]::ReadAllBytes($HtmlPath)) 'text/html; charset=utf-8' 200
          } else {
            Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes($FALLBACK)) 'text/html; charset=utf-8' 200
          }
          break
        }

        '/health' {
          Send-Json $ctx @{
            ok      = $true
            version = $VERSION
            ytdlp   = [bool](Find-Tool 'yt-dlp')
            ffmpeg  = [bool](Find-Tool 'ffmpeg')
            folder  = $DownDir
          }
          break
        }

        '/fetch' {
          $body = Read-Body $ctx
          $url  = $null
          if ($body) { $url = [string]$body.url }
          if ([string]::IsNullOrWhiteSpace($url)) { Send-Json $ctx @{ error = 'Kein Link uebergeben.' } 400; break }
          if ($url -notmatch '^https?://')        { Send-Json $ctx @{ error = 'Link muss mit http(s):// beginnen.' } 400; break }

          $id = Get-JobId $url
          Write-Host ("[fetch] {0}" -f $url) -ForegroundColor Cyan

          $existing = Get-MediaFile $id
          if ($existing) {
            Write-Host "  -> bereits vorhanden, kein erneuter Download" -ForegroundColor DarkGray
            Send-Json $ctx @{ id = $id; state = 'done'; cached = $true; title = (Get-JobTitle $id) }
            break
          }
          $job = $script:jobs[$id]
          if ($job -and -not $job.proc.HasExited) { Send-Json $ctx @{ id = $id; state = 'running' }; break }

          try { Start-Fetch $url $id; Send-Json $ctx @{ id = $id; state = 'running' } }
          catch { Send-Json $ctx @{ error = $_.Exception.Message } 500 }
          break
        }

        '/job' {
          $id = $req.QueryString['id']
          if (-not $id) { Send-Json $ctx @{ error = 'id fehlt' } 400; break }
          $st = Get-JobState $id
          $st['id'] = $id
          Send-Json $ctx $st
          break
        }

        '/media' {
          $id = $req.QueryString['id']
          $file = $null
          if ($id) { $file = Get-MediaFile $id }
          if (-not $file) { Send-Json $ctx @{ error = 'Datei nicht gefunden' } 404; break }

          $res = $ctx.Response
          $res.StatusCode = 200
          $res.ContentType = $(if ($file.Extension -eq '.webm') { 'video/webm' } else { 'video/mp4' })
          $res.ContentLength64 = $file.Length
          Add-Cors $res
          $fs = [IO.File]::OpenRead($file.FullName)
          try { $fs.CopyTo($res.OutputStream) } finally { $fs.Close() }
          $res.OutputStream.Close()
          Write-Host ("[media] {0} ({1:N1} MB)" -f $file.Name, ($file.Length / 1MB)) -ForegroundColor DarkGray
          break
        }

        '/library' {
          $items = @()
          Get-ChildItem -Path $DownDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '^\.(mp4|webm|mkv|mov|m4v)$' } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 40 |
            ForEach-Object {
              $bid = [IO.Path]::GetFileNameWithoutExtension($_.Name)
              $items += @{ id = $bid; title = (Get-JobTitle $bid); size = $_.Length; date = $_.LastWriteTime.ToString('s') }
            }
          Send-Json $ctx @{ items = $items }
          break
        }

        default { Send-Json $ctx @{ error = 'Unbekannter Endpunkt' } 404 }
      }
    }
    catch {
      Write-Host ("[fehler] {0}" -f $_.Exception.Message) -ForegroundColor Red
      try { Send-Json $ctx @{ error = $_.Exception.Message } 500 } catch { }
    }
  }
}
finally {
  try { $listener.Stop(); $listener.Close() } catch { }
  Write-Host "Helfer beendet." -ForegroundColor DarkGray
}
