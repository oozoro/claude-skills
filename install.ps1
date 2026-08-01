# Claude Code にカスタムスキルを導入する（Windows / PowerShell）
#
#   新しいマシンで（認証不要）:
#     irm https://raw.githubusercontent.com/oozoro/claude-skills/main/install.ps1 | iex
#
#   クローン済みなら:
#     powershell -ExecutionPolicy Bypass -File install.ps1
#
# 何度実行しても同じ結果になる（既存のものを消してから入れ直す）。
#
# 注意: Claude Code を WSL 上で動かしている場合、ここが書き込む
# %USERPROFILE%\.claude は参照されない。WSL 側で install.sh を実行すること。
$ErrorActionPreference = 'Stop'

$RepoUrl    = if ($env:SKILL_REPO_URL)    { $env:SKILL_REPO_URL }    else { 'https://github.com/oozoro/claude-skills.git' }
$RepoBranch = if ($env:SKILL_REPO_BRANCH) { $env:SKILL_REPO_BRANCH } else { 'main' }
$Dest       = Join-Path $env:USERPROFILE '.claude\skills'

# スクリプトがリポジトリのクローン内から実行されたかを判定する。
# irm | iex の場合は $PSScriptRoot が空になり、下の clone に落ちる。
$root = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'skills'))) {
    $root = $PSScriptRoot
}

$tmp = $null
if (-not $root) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git が必要です。先に git を入れてください。'
    }
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("skills-" + [System.Guid]::NewGuid().ToString('N'))
    Write-Host "取得中: $RepoUrl ($RepoBranch)"
    # core.autocrlf=false は、改行が CRLF に変換されて SKILL.md 冒頭の
    # YAML が壊れるのを防ぐため。Windows では既定で有効なので必須。
    git -c core.autocrlf=false clone -q --depth 1 -b $RepoBranch $RepoUrl $tmp
    if ($LASTEXITCODE -ne 0) { throw "clone に失敗しました: $RepoUrl ($RepoBranch)" }
    $root = $tmp
}

try {
    $skills = Get-ChildItem (Join-Path $root 'skills') -Directory |
              Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }
    if (-not $skills) { throw '導入できるスキルが見つかりません。' }

    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    foreach ($s in $skills) {
        $target = Join-Path $Dest $s.Name
        if (Test-Path $target) { Remove-Item -Recurse -Force $target }
        Copy-Item -Recurse $s.FullName $target
        Write-Host "導入しました: $target"
    }
    Write-Host ''
    Write-Host 'Claude Code を再起動すると読み込まれます。'
}
finally {
    if ($tmp -and (Test-Path $tmp)) { Remove-Item -Recurse -Force $tmp }
}
