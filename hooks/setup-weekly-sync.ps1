# Claude Code に「週1回、起動時にスキルを自動更新する」フックを1回だけ登録する（Windows）
#
#   irm https://raw.githubusercontent.com/oozoro/claude-skills/main/hooks/setup-weekly-sync.ps1 | iex
#
# %USERPROFILE%\.claude\settings.json に SessionStart フックを追記する。既存の設定は
# 保持し、二重登録もしない（何度実行しても同じ結果になる）。
#
# 登録されるフックの動作:
#   Claude Code 起動のたびに、前回同期から7日経っていなければ即終了（通信しない）。
#   7日以上経っていれば、install.sh を実行してスキルを最新化する。
# フック自体は bash（Git for Windows 同梱の Git Bash）で実行される。
# Windows PowerShell 5.1 / PowerShell 7 のどちらでも動くように書いてある。
$ErrorActionPreference = 'Stop'

$path = Join-Path $env:USERPROFILE '.claude\settings.json'

# SessionStart で毎回実行されるチェック本体。7日以内なら即 exit し、通信しない。
$cmd = 'stamp="$HOME/.claude/skills/.claude-skills-last-sync"; now=$(date +%s); last=0; [ -f "$stamp" ] && last=$(cat "$stamp" 2>/dev/null || echo 0); age=$(( now - last )); if [ "$age" -lt 604800 ]; then exit 0; fi; mkdir -p "$HOME/.claude/skills"; log="$HOME/.claude/skills/.claude-skills-sync.log"; if curl -fsSL https://raw.githubusercontent.com/oozoro/claude-skills/main/install.sh 2>>"$log" | bash >>"$log" 2>&1; then echo "$now" > "$stamp"; else echo "$(date): sync failed" >> "$log"; fi'

if (Test-Path $path) {
    try {
        $json = Get-Content $path -Raw | ConvertFrom-Json
    } catch {
        throw "既存の $path が壊れています（JSON として読めません）。手動で確認してください。"
    }
} else {
    $json = New-Object PSObject
}

if (-not ($json.PSObject.Properties.Name -contains 'hooks')) {
    $json | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject)
}
if (-not ($json.hooks.PSObject.Properties.Name -contains 'SessionStart')) {
    $json.hooks | Add-Member -NotePropertyName SessionStart -NotePropertyValue @()
}

$exists = $false
foreach ($grp in @($json.hooks.SessionStart)) {
    foreach ($h in @($grp.hooks)) {
        if ($h.command -eq $cmd) { $exists = $true }
    }
}

if ($exists) {
    Write-Host "既に登録済みです（変更なし）: $path"
} else {
    $newHook = [PSCustomObject]@{
        type          = 'command'
        command       = $cmd
        shell         = 'bash'
        async         = $true
        timeout       = 90
        statusMessage = 'スキルを同期中...'
    }
    $newEntry = [PSCustomObject]@{ hooks = @($newHook) }
    $json.hooks.SessionStart = @($json.hooks.SessionStart) + $newEntry
    Write-Host "フックを登録しました: $path"
}

New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null

# PS 5.1 の Set-Content -Encoding utf8 は BOM 付きで書き出し、settings.json の
# JSON パースを壊すことがあるため、BOM 無し UTF-8 で明示的に書き込む。
$content = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Claude Code を再起動すると有効になります。"
