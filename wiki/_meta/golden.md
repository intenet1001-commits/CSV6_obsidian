---
title: "Golden Eval Scenarios"
type: overview
status: stable
created: 2026-04-07
updated: 2026-04-07
---

# Golden Eval

회귀 테스트용 baseline. lint 통과 ≠ 시스템 정상이므로 별도 평가.
새 ingest/query/lint 로직 변경 시 이 시나리오들이 통과해야 한다.

## Scenario 1: Karpathy gist ingest

**Input**: `raw/karpathy-llm-wiki.md` (https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f 텍스트)

**Expected after `/llm-wiki ingest`**:
- `wiki/summaries/karpathy-llm-wiki.md` 생성, frontmatter에 source_hash 포함
- `wiki/concepts/llm-wiki.md` 신규 (개념 페이지)
- `wiki/concepts/compile-once.md` 신규
- `wiki/entities/karpathy.md` 신규
- `wiki/topics/knowledge-management/index.md`에 항목 추가
- `wiki/master-index.md`에 4+ 항목 등록
- `wiki/log.md`에 INGEST 1줄 append
- 모든 신규 페이지에 [[wikilink]] 최소 3개

## Scenario 2: 비교 query

**Q**: "LLM Wiki와 일반 RAG의 차이?"

**Expected after `/llm-wiki query`**:
- 답변에 `[[llm-wiki]]`, `[[compile-once]]` 인용 포함
- raw/를 직접 읽지 않음 (master-index + 관련 wiki 페이지만 참조)
- 답변 길이 < 500자
- log.md에 QUERY 1줄

## Scenario 3: 첫 lint

**Expected after `/llm-wiki lint` (Scenario 1, 2 후)**:
- orphan: 0
- dead-link: 0
- broken: 0
- stale: 0 (방금 ingest 했으므로)
- un-ingested: 0
- PII: 0
- duplicate: 0
- log.md에 LINT 1줄

## Scenario 4: stale 감지 회귀

**Setup**: Scenario 1 이후 raw/karpathy-llm-wiki.md 본문에 한 줄 추가.

**Expected after `/llm-wiki lint`**:
- stale=1 (karpathy-llm-wiki.md hash mismatch)
- 사용자에게 `/llm-wiki ingest raw/karpathy-llm-wiki.md` 권장 출력

## Scenario 5: PII 회귀

**Setup**: `wiki/concepts/test-pii.md`에 가짜 주민번호 `900101-1234567` 삽입.

**Expected after `/llm-wiki lint`**:
- PII 경고: 1건 (test-pii.md, 주민번호 패턴)

## Scenario 6: broken frontmatter 회귀

**Setup**: `raw/broken.md`에 잘못된 frontmatter (닫는 `---` 누락).

**Expected after `/llm-wiki ingest`**:
- `wiki/_broken/broken.md` 격리
- log.md에 BROKEN 이벤트
- raw/broken.md는 그대로 유지

## 실행 권장 주기
- Scenario 1-3: 첫 dogfood 시 1회
- Scenario 4-6: 매월 1회 또는 SKILL.md 변경 시
