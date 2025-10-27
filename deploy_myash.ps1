$ErrorActionPreference = 'Stop'

git checkout gh-pages
git pull

flutter build web --release --pwa-strategy=none --base-href /myash/
Set-Location build\web

$v = Get-Date -UFormat %Y%m%d%H%M%S
git add -A
git commit -m "Auto deploy $v"
git push origin gh-pages

$url = "https://myash2025.github.io/myash/?v=$v"

# ---- ブラウザ（ゲスト）で開く ----
$brave  = Get-Command 'brave.exe'  -ErrorAction SilentlyContinue
$chrome = Get-Command 'chrome.exe' -ErrorAction SilentlyContinue

if ($brave) {
    Start-Process $brave.Source  -ArgumentList @('--new-window','--guest',$url)
}
elseif ($chrome) {
    Start-Process $chrome.Source -ArgumentList @('--new-window','--guest',$url)
}
else {
    Write-Warning 'Brave/Chrome not found. Open with default browser.'
    Start-Process $url
}
