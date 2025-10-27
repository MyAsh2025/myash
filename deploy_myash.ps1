$ErrorActionPreference = 'Stop'

# 1) Build & push
git checkout gh-pages
git pull
flutter build web --release --pwa-strategy=none --base-href /myash/
Set-Location build\web

$v = Get-Date -UFormat %Y%m%d%H%M%S
git add -A
git commit -m "Auto deploy $v"
git push origin gh-pages

# 2) URL with cache-busting
$url = "https://myash2025.github.io/myash/?v=$v"

# 3) Launch browser with a fresh, temporary profile (always logged-out)
$profileDir = Join-Path $env:TEMP ("myash_ephemeral_{0}" -f $v)
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

# Try to find Brave
$brave = $null
try { $brave = (Get-Command brave.exe -ErrorAction Stop).Source } catch {}
if (-not $brave) {
  $brave = @(
    "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
    "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

# Try to find Chrome
$chrome = $null
try { $chrome = (Get-Command chrome.exe -ErrorAction Stop).Source } catch {}
if (-not $chrome) {
  $chrome = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

# Common arguments: clean temporary profile so it never uses logged-in state
$commonArgs = @(
  '--new-window',
  "--user-data-dir=$profileDir",
  '--no-first-run',
  '--no-default-browser-check',
  $url
)

if ($brave) {
  Start-Process -FilePath $brave -ArgumentList $commonArgs
}
elseif ($chrome) {
  Start-Process -FilePath $chrome -ArgumentList $commonArgs
}
else {
  Write-Warning "Brave/Chrome not found. Opening with system default browser."
  Start-Process $url
}

# 4) (optional) cleanup old temp profiles (>7 days)
Get-ChildItem "$env:TEMP\myash_ephemeral_*" -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
