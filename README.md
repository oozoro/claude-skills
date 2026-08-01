# claude-skills

Claude Code / claude.ai で使うカスタムスキルの置き場。

複数マシン（Mac Studio / MacBook / Windows）で同じスキルを使うための、単一の正本。

## 導入

新しいマシンでも、更新時でも、同じコマンドでよい。**何度実行しても同じ結果になる。**

### macOS / Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/oozoro/claude-skills/main/install.sh | bash
```

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/oozoro/claude-skills/main/install.ps1 | iex
```

`~/.claude/skills/`（Windows は `%USERPROFILE%\.claude\skills\`）に配置される。実行後に Claude Code を再起動すれば読み込まれる。

このリポジトリは public なので、**認証は不要**。git さえ入っていれば新品のマシンでそのまま通る。

### 特定のスキルだけ入れる

```bash
bash install.sh strategy-advisor
```

引数を省略すると `skills/` 配下すべてを導入する。

### claude.ai / デスクトップアプリ

こちらはアカウントに紐づくため、**マシンを変えても再導入は不要**。ログインするだけで使える状態に戻る。

新しく入れ直す場合のみ、`skills/*.skill` をアップロードする。

---

## 収録スキル

### strategy-advisor

軍事理論（孫子・クラウゼヴィッツ・ランチェスター）と経営戦略論（ポーター・RBV・エコシステム）を統合した、事業戦略の診断・処方フレームワーク。

競合との戦い方、市場での立ち位置、リソース配分、差別化、参入・撤退、価格競争、シェア争いといった相談で自動的に起動する。「戦略」という言葉が出てこなくても、「大手に勝てない」「勝ち筋が見えない」「施策は当たっているのに事業が伸びない」といった相談を拾う。

資源で劣る側の戦い方（弱者の戦略、機動戦、資本効率を武器にする方法）も扱う。

---

## 週1回、自動で最新化する（任意）

3台それぞれで導入コマンドを手動で打ち直す代わりに、Claude Code 起動時に自動でチェックさせることができる。**各マシンで最初に1回だけ実行すれば、以後は何もしなくていい。**

### macOS / Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/oozoro/claude-skills/main/hooks/setup-weekly-sync.sh | bash
```

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/oozoro/claude-skills/main/hooks/setup-weekly-sync.ps1 | iex
```

これは `~/.claude/settings.json`（Windows は `%USERPROFILE%\.claude\settings.json`）に SessionStart フックを1件追加するだけで、既存の設定は保持される。何度実行しても二重登録しない。

**動作:** Claude Code を起動するたびに、前回の同期から7日以内なら何もせず即終了する（通信しない）。7日以上経っていれば、バックグラウンドで `install.sh` を実行してスキルを最新化する。起動が遅くなることはない（非同期実行）。ログは `~/.claude/skills/.claude-skills-sync.log` に残る。

Windows でもフック自体は bash（Git for Windows 同梱の Git Bash）で動く。Git for Windows が入っていない環境では動作しない。

無効化したい場合は、`~/.claude/settings.json` の `hooks.SessionStart` から `.claude-skills-last-sync` を含むエントリを削除する。

---

## スキルを更新するとき

1. `skills/<name>/` を編集して main に push する
2. 各マシンで上の導入コマンドをもう一度実行する（上書きされる）
3. claude.ai 側も使っているなら、`.skill` を作り直してアップロードし直す

`.skill` の作り直しは skill-creator の `package_skill` で行う。

```bash
python3 -m scripts.package_skill skills/strategy-advisor
```

## スキルを追加するとき

`skills/<name>/SKILL.md` を作れば、インストーラは自動で拾う。スクリプト側の変更は不要。

---

## 構成

```
skills/
├── strategy-advisor/          Claude Code 用（ディレクトリのまま配置される）
│   ├── SKILL.md
│   └── references/
└── strategy-advisor.skill     claude.ai / デスクトップアプリ用のバンドル
install.sh                     macOS / Linux / WSL
install.ps1                    Windows
hooks/
├── setup-weekly-sync.sh       週1自動同期フックの登録（macOS / Linux / WSL）
└── setup-weekly-sync.ps1      同上（Windows）
```

インストーラの参照先は環境変数で差し替えられる。フォークした場合などに使う。

```bash
SKILL_REPO_URL=https://github.com/<user>/<repo>.git \
SKILL_REPO_BRANCH=main bash install.sh
```
