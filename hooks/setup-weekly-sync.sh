#!/usr/bin/env bash
# Claude Code に「週1回、起動時にスキルを自動更新する」フックを1回だけ登録する
# （macOS / Linux / WSL、Windows は Git Bash 経由でも動く）
#
#   curl -fsSL https://raw.githubusercontent.com/oozoro/claude-skills/main/hooks/setup-weekly-sync.sh | bash
#
# ~/.claude/settings.json に SessionStart フックを追記する。既存の設定は保持し、
# 二重登録もしない（何度実行しても同じ結果になる）。
#
# 登録されるフックの動作:
#   Claude Code 起動のたびに、前回同期から7日経っていなければ即終了（通信しない）。
#   7日以上経っていれば、install.sh を実行してスキルを最新化する。
set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "python3 が必要です。" >&2; exit 1; }

python3 - <<'PY'
import json, os

p = os.path.expanduser("~/.claude/settings.json")

# SessionStart で毎回実行されるチェック本体。7日以内なら即 exit し、通信しない。
CMD = (
    'stamp="$HOME/.claude/skills/.claude-skills-last-sync"; '
    'now=$(date +%s); last=0; '
    '[ -f "$stamp" ] && last=$(cat "$stamp" 2>/dev/null || echo 0); '
    'age=$(( now - last )); '
    'if [ "$age" -lt 604800 ]; then exit 0; fi; '
    'mkdir -p "$HOME/.claude/skills"; '
    'log="$HOME/.claude/skills/.claude-skills-sync.log"; '
    'if curl -fsSL https://raw.githubusercontent.com/oozoro/claude-skills/main/install.sh '
    '2>>"$log" | bash >>"$log" 2>&1; then echo "$now" > "$stamp"; '
    'else echo "$(date): sync failed" >> "$log"; fi'
)

try:
    with open(p) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data.setdefault("hooks", {}).setdefault("SessionStart", [])

existing_cmds = [
    h.get("command")
    for grp in data["hooks"]["SessionStart"]
    for h in grp.get("hooks", [])
]

if CMD not in existing_cmds:
    data["hooks"]["SessionStart"].append({
        "hooks": [{
            "type": "command",
            "command": CMD,
            "shell": "bash",
            "async": True,
            "timeout": 90,
            "statusMessage": "スキルを同期中...",
        }]
    })
    print("フックを登録しました:", p)
else:
    print("既に登録済みです（変更なし）:", p)

os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "Claude Code を再起動すると有効になります。"
