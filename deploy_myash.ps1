$ErrorActionPreference="Stop"
git checkout gh-pages
git pull
flutter build web --release --pwa-strategy=none --base-href /myash/
Set-Location build\web
$v=Get-Date -UFormat %Y%m%d%H%M%S
git add -A
git commit -m "Auto deploy $v"
git push origin gh-pages
$url="https://myash2025.github.io/myash/?v=$v"
if (Get-Command brave.exe -ErrorAction SilentlyContinue) { Start-Process brave.exe $url } else { Start-Process $url }
