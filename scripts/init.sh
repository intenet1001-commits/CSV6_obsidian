#!/usr/bin/env bash
#
# init.sh — CS_V6 Obsidian LLM Wiki 첫 설치 부트스트랩
#
# 역할: templates/ 아래의 빈 템플릿들을 wiki/ 의 올바른 위치로 복사한다.
#       이 스크립트는 처음 clone 받은 뒤 단 한 번만 실행한다.
#
# Idempotent: 이미 wiki/ 파일이 존재하면 덮어쓰지 않고 skip.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

declare -a MAPPINGS=(
  "templates/master-index.md:wiki/master-index.md"
  "templates/log.md:wiki/log.md"
  "templates/glossary.md:wiki/_meta/glossary.md"
)

echo "CS_V6 — LLM Wiki bootstrap"
echo "──────────────────────────"

for mapping in "${MAPPINGS[@]}"; do
  src="${mapping%%:*}"
  dst="${mapping##*:}"

  if [[ -f "$dst" ]]; then
    echo "⏭  skip  $dst (already exists)"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "✓  copy  $src → $dst"
  fi
done

echo ""
echo "완료. 이제 Obsidian에서 이 폴더를 열고,"
echo "Claude Code에서 '/llm-wiki ingest' 로 첫 raw 를 컴파일하세요."
