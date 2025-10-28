[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ログ（失敗時の調査用）
$log = Join-Path $env:TEMP ("deploy_myash_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
Start-Transcript -Path $log -Append | Out-Null

# スクリプトのある場所＝プロジェクトルートへ
Set-Location -Path $PSScriptRoot

if (-not (Test-Path 'pubspec.yaml')) {
    throw 'pubspec.yaml が見つかりません。Flutter プロジェクトのルートで実行してください。'
}

Write-Verbose 'Git: checkout gh-pages' -Verbose
git checkout gh-pages

Write-Verbose 'Git: pull' -Verbose
git pull --ff-only

Write-Verbose 'Flutter: pub get' -Verbose
flutter pub get

Write-Verbose 'Flutter: build web' -Verbose
flutter build web --release --pwa-strategy=none --base-href /myash/

# 成果物へ移動
Set-Location -Path 'build\web'

# キャッシュバスター
$v = Get-Date -Format 'yyyyMMddHHmmss'

Write-Verbose 'Git: add/commit/push' -Verbose
git add -A
git commit -m "Auto deploy $v" 2>$null   # 変更なしなら commit はスキップ
git push origin gh-pages

# 既定ブラウザで開く（まずは既定でOK。ゲスト起動は後段）
$url = "https://myash2025.github.io/myash/?v=$v"
Write-Host "Open: $url" -ForegroundColor Cyan
Start-Process $url

Stop-Transcript | Out-Null
Write-Host "ログ: $log" -ForegroundColor DarkGray
