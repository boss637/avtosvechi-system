#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TS="$(date -u +'%Y-%m-%d_%H%M')"
OUT="project/handovers/${TS}_handover.md"
STATE="project/PROJECT_STATE.md"

mkdir -p project/handovers

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')"
HEADSHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'no-git')"

{
  echo "# Handover ${TS} UTC"
  echo
  echo "## Repo"
  echo "- Branch: ${BRANCH}"
  echo "- HEAD: ${HEADSHA}"
  echo
  echo "## Uncommitted changes (porcelain)"
  echo '```
  git status --porcelain || true
  echo '```'
  echo
  echo "## Diff stat"
  echo '```
  git diff --stat || true
  echo '```'
  echo
  echo "## Untracked files"
  echo '```
  git ls-files --others --exclude-standard || true
  echo '```'
  echo
  echo "## Recent commits"
  echo '```
  git log -n 20 --date=iso --pretty=format:'%h %ad %s' || true
  echo
  echo '```'
  echo
  echo "## TODO / Debt (fill manually)"
  echo "- [ ] Команды, которые пользователь должен выполнить, но не выполнил: (дополнить)"
  echo "- [ ] Открытые решения/вопросы: (дополнить)"
  echo "- [ ] Риски/заметки: (дополнить)"
  echo
  echo "## Next steps (fill manually)"
  echo "- [ ] (дополнить)"
} > "${OUT}"

cp -f "${OUT}" "${STATE}"

echo "Created:"
echo "${OUT}"
echo "${STATE}"
