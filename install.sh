#!/usr/bin/env bash
# Claude Code にカスタムスキルを導入する（macOS / Linux / WSL）
#
#   新しいマシンで（認証不要）:
#     curl -fsSL https://raw.githubusercontent.com/oozoro/claude-skills/main/install.sh | bash
#
#   クローン済みなら:
#     bash install.sh
#
#   特定のスキルだけ入れる:
#     bash install.sh strategy-advisor
#
# 何度実行しても同じ結果になる（既存のものを消してから入れ直す）。
#
# set -u を使っていないのは意図的。macOS 標準の bash 3.2 は set -u 下で
# 空配列の ${#arr[@]} を参照するとエラーになるため。
set -eo pipefail

REPO_URL="${SKILL_REPO_URL:-https://github.com/oozoro/claude-skills.git}"
REPO_BRANCH="${SKILL_REPO_BRANCH:-main}"
DEST="$HOME/.claude/skills"

# スクリプトがリポジトリのクローン内から実行されたかを判定する。
# curl | bash の場合はここが空振りして、下の clone に落ちる。
ROOT=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [ -d "$script_dir/skills" ] && ROOT="$script_dir"
fi

if [ -z "$ROOT" ]; then
  command -v git >/dev/null 2>&1 || { echo "git が必要です。先に git を入れてください。" >&2; exit 1; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "取得中: $REPO_URL ($REPO_BRANCH)"
  # core.autocrlf=false は、改行が CRLF に変換されて SKILL.md 冒頭の
  # YAML が壊れるのを防ぐため。WSL 経由だと既定で有効なことがある。
  git -c core.autocrlf=false clone -q --depth 1 -b "$REPO_BRANCH" "$REPO_URL" "$tmp"
  ROOT="$tmp"
fi

# 引数があればそのスキルだけ、無ければ skills/ 配下すべてを対象にする。
names=()
if [ $# -gt 0 ]; then
  names=("$@")
else
  for d in "$ROOT"/skills/*/; do
    [ -f "$d/SKILL.md" ] && names+=("$(basename "$d")")
  done
fi
[ ${#names[@]} -gt 0 ] || { echo "導入できるスキルが見つかりません。" >&2; exit 1; }

mkdir -p "$DEST"
for name in "${names[@]}"; do
  src="$ROOT/skills/$name"
  [ -f "$src/SKILL.md" ] || { echo "スキルが見つかりません: $name" >&2; exit 1; }
  rm -rf "${DEST:?}/$name"
  cp -R "$src" "$DEST/"
  echo "導入しました: $DEST/$name"
done

echo
echo "Claude Code を再起動すると読み込まれます。"
