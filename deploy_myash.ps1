[CmdletBinding()]
Param(
    [string]$CustomDomain = "",
    [string]$RepoRoot      = (Get-Location).Path,
    [string]$GhPagesBranch = "gh-pages",
    [string]$BuildDir      = "build\web",
    [string[]]$FlutterBuildExtraArgs = @(),
    [bool]$FlutterClean    = $false,

    [ValidateSet("guest","default")]
    [string]$OpenMode = "guest",

    [ValidateSet("Brave","Chrome","Edge")]
    [string]$PreferredBrowser = "Brave"
)
# DO NOT MOVE: keep Param() at very top with nothing before it.
$ErrorActionPreference = 'Stop'




function Log([string]$m) {
  Write-Host ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m)
}

function Need([string]$cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $cmd"
  }
}

# 可変長引数を安全に受け取り、1個の長い文字列なら分割して git へ渡す
function Run {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$cmd,
        [Parameter(ValueFromRemainingArguments=$true, Position=1)]
        [string[]]$rest
    )

    if ($rest.Count -eq 1 -and ($rest[0] -match '\s')) {
        $rest = $rest[0] -split '\s+'
    }

    Log ">> $cmd $($rest -join ' ')"
    & $cmd @rest

    if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $cmd $($rest -join ' ')"
    }
}

function SafeClearExceptGit([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return }
  Get-ChildItem -LiteralPath $p -Force | ForEach-Object {
    if ($_.Name -eq '.git') { return }
    if ($_.PSIsContainer) {
      Remove-Item -LiteralPath $_.FullName -Recurse -Force
    } else {
      Remove-Item -LiteralPath $_.FullName -Force
    }
  }
}


function RemoteHasBranch([string]$remote,[string]$branch){
  $o = & git ls-remote --heads $remote $branch
  return -not [string]::IsNullOrWhiteSpace($o)
}

function ParseGitHub(){
  $url = (& git remote get-url origin).Trim()
  if($url -match '^https://github\.com/([^/]+)/([^/]+?)(\.git)?$' -or $url -match '^git@github\.com:([^/]+)/([^/]+?)(\.git)?$'){
    return @{ owner=$Matches[1]; repo=$Matches[2] }
  }
  throw "Unsupported GitHub remote: $url"
}

function Find-BrowserPath([string]$name){
  $c = switch ($name) {
    "Brave"  { @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe") }
    "Chrome" { @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") }
    "Edge"   { @("$env:ProgramFiles (x86)\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") }
  }
  foreach($p in $c){ if(Test-Path -LiteralPath $p){ return $p } }
  return $null
}

# 一時プロファイルディレクトリを作る（毎回空のプロフィール）
function New-TempProfileDir([string]$name){
    $base = Join-Path $env:TEMP "myash_browser_profiles"
    New-Item -ItemType Directory -Force -Path $base | Out-Null
    $dir = Join-Path $base ("{0}_{1}" -f $name, [guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    return $dir
}

function Open-Url([string]$url,[string]$mode,[string]$preferred){
    if($mode -eq "default"){ Log "Opening default: $url"; Start-Process $url | Out-Null; return }

    # 検索順: 指定 > Brave > Chrome > Edge
    $order = @($preferred, "Brave","Chrome","Edge") | Select-Object -Unique

    foreach($n in $order){
        $bin = Find-BrowserPath $n; if(-not $bin){ continue }

        if($n -in @("Brave","Chrome")){
            # まっさらプロファイルで起動（サインイン情報を絶対に拾わない）
            $dir = New-TempProfileDir ($n.ToLower())
            $args = @(
                "--user-data-dir=""$dir""",
                "--no-first-run",
                "--disable-sync",
                "--new-window"
            )
            if($mode -eq "guest"){ $args += "--guest" }  # シークレットより強い“ゲスト”
            Log "Opening $n with isolated profile as $mode …"
            Start-Process -FilePath $bin -ArgumentList ($args + $url) | Out-Null
            return
        }
        elseif($n -eq "Edge"){
            # Edge は --guest が効かない環境があるので InPrivate で代替
            $args = @("--inprivate","--new-window",$url)
            Log "Opening Edge InPrivate as $mode …"
            Start-Process -FilePath $bin -ArgumentList $args | Out-Null
            return
        }
    }

    Log "No supported browser found; fallback default"; Start-Process $url | Out-Null
}



try {
  Log "=== MyAsh minimal deploy start ==="
  Set-Location -LiteralPath $RepoRoot
  Need "git"; Need "flutter"
  Run git @("rev-parse","--is-inside-work-tree") | Out-Null
  Run git @("remote","get-url","origin") | Out-Null
  Run git @("fetch","origin","--prune")

  if($FlutterClean){ Run flutter @("clean") }

  $fb = @("build","web","--release")
  if($FlutterBuildExtraArgs.Count -gt 0){ $fb += $FlutterBuildExtraArgs }
  Log "Flutter build web..."; Run flutter $fb

  $buildPath = Join-Path $RepoRoot $BuildDir
  if(-not (Test-Path -LiteralPath $buildPath)){ throw "Build output not found: $buildPath" }

  $work = Join-Path $RepoRoot ".gh-pages"
  $hasRemote = RemoteHasBranch "origin" $GhPagesBranch

  # always start from clean worktree dir
  try{ Run git @("worktree","remove","--force",$work) } catch {}
  if(Test-Path -LiteralPath $work){ Remove-Item -LiteralPath $work -Recurse -Force }

  if($hasRemote){
    Run git @("worktree","add",$work,"origin/$GhPagesBranch")
  } else {
    Run git @("worktree","add","-B",$GhPagesBranch,$work)
    Push-Location $work
    Run git @("add","--all")
    # allow-empty: 初回でも確実にブランチ作成
    Run git @("commit","--allow-empty","-m","chore: init gh-pages")
    Run git @("push","-u","origin",$GhPagesBranch)
    Pop-Location
  }

Log "Sync build -> gh-pages"

SafeClearExceptGit $work
New-Item -ItemType Directory -Force -Path $work | Out-Null

if (-not (Test-Path $buildPath)) {
  throw "Build directory not found: $buildPath"
}

Copy-Item -Path (Join-Path $buildPath '*') -Destination $work -Recurse -Force -ErrorAction Stop

New-Item -Path (Join-Path $work '.nojekyll') -ItemType File -Force | Out-Null
if ($customDomain -and $customDomain.Trim() -ne "") {
    Set-Content -Path (Join-Path $work 'CNAME') -Value $customDomain -Encoding ascii
}


  Run git @("add","-A")
  $st = (& git status --porcelain).Trim()
  if($st){
    $msg = "deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Run git @("commit","-m",$msg)
    Run git @("push","origin",$GhPagesBranch)
  } else {
    Log "No changes to commit."
  }
  Pop-Location

  # URL
  $url = if($CustomDomain){ "https://$CustomDomain" } else {
    $gh = ParseGitHub
    if($gh.repo -ieq "$($gh.owner).github.io"){ "https://$($gh.owner).github.io/" } else { "https://$($gh.owner).github.io/$($gh.repo)/" }
  }

  Log "OpenMode=$OpenMode Preferred=$PreferredBrowser"
  Open-Url -url $url -mode $OpenMode -preferred $PreferredBrowser

  Write-Host "`n✅ Deploy finished successfully." -ForegroundColor Green
  Write-Host "URL: $url"
  Write-Host "OpenMode: $OpenMode (Preferred: $PreferredBrowser)"
}
catch {
  Write-Host "`n❌ Deploy failed." -ForegroundColor Red
  Write-Host $_.Exception.Message
  if($_.ScriptStackTrace){ Write-Host "`nStack:`n$($_.ScriptStackTrace)" }
  exit 1
}
