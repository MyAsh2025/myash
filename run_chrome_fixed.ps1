$Port   = 49265
$Chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$PersistEnv = $true

function W($m,$c="Cyan"){ Write-Host $m -ForegroundColor $c }
if (-not (Test-Path $Chrome)) { W "Chrome が見つかりません: $Chrome" "Yellow"; exit 1 }
$env:CHROME_EXECUTABLE = $Chrome
if ($PersistEnv) { setx CHROME_EXECUTABLE "$Chrome" | Out-Null }

W "[flutter pub get]" "Gray"
flutter pub get

W "[run] Chrome 固定ポート: $Port" "Green"
flutter run -d chrome --web-hostname localhost --web-port $Port
