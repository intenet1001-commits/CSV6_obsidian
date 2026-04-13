# CS_V6 LLM Wiki — 사용 매뉴얼

> Karpathy의 LLM Wiki 패턴을 한국어 Obsidian 볼트로 구현. AI가 raw 자료를 컴파일해 누적 가능한 지식베이스를 만든다.
>
> **참고**: [Karpathy gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) · [gpters.org 한국어 가이드](https://www.gpters.org/nocode/post/obsidian-rag-setup-guide-GmwUMcONgl3ZSV3)

---

## 1. 이게 뭔가

전통적 RAG(벡터 검색)와 다른 패턴이다. **한 번 정제해서 누적**하는 컴파일형 지식베이스.

- **사람**: raw/에 자료를 던지고 질문만 한다.
- **LLM (Claude Code)**: raw → wiki 컴파일, 개념 페이지 갱신, 양방향 링크 직조, 주간 시놉시스 생성, 건강체크.
- **Markdown이 곧 데이터베이스**. 벡터 DB·임베딩 없음.
- **Obsidian Graph view**가 시각적 인터페이스 (콘셉트 클러스터 발견).

수백 페이지 규모까지 효율적. 1000+ 넘으면 LightRAG 같은 도구로 export 가능 (frontmatter 표준 덕분).

---

## 2. 폴더 구조

```
CS_V6/
├── CLAUDE.md                          ← LLM 운영 매뉴얼 (스키마 + 컨벤션)
├── AGENTS.md                          ← CLAUDE.md alias
├── README.md                          ← 사람용 5줄
├── MANUAL.md                          ← 이 파일
│
├── .claude/skills/llm-wiki/
│   └── SKILL.md                       ← /llm-wiki 운영 로직 풀버전
│
├── raw/                               ← 불변 원본 (flat)
│   ├── *.md                           ← Web Clipper / 수동 저장
│   └── _attachments/                  ← Obsidian 첨부 (이미지·PDF)
│
└── wiki/                              ← LLM 생성 정제물
    ├── master-index.md                ← 전체 카탈로그 (모든 query 시작점)
    ├── log.md                         ← append-only 활동 로그
    ├── open-questions.md              ← 답 못한 query 누적
    ├── concepts/                      ← 단일 진리원 개념 페이지
    ├── entities/                      ← 사람·도구·회사
    ├── topics/<t>/index.md            ← 주제 클러스터 (각자 MOC)
    ├── summaries/                     ← raw 1:1 요약
    ├── queries/                       ← 승격된 Q&A
    ├── digests/                       ← 주간 자동 시놉시스
    ├── _meta/                         ← golden / stats / glossary
    ├── _broken/                       ← 파싱 실패 격리
    └── _scratch/                      ← Obsidian 새 노트 기본 위치
```

**핵심 원칙**:
- **raw 진짜 불변**: 한 글자도 안 건드린다. 경로도 안 바뀐다.
- **단일 진리원**: ingest 상태 = `wiki/summaries/<slug>.md` 존재 여부. manifest 같은 보조 진리원 없음.
- **stale 감지**: summary `source_hash` ≠ 현재 raw 파일 sha256 → raw 변경됨 → 재-ingest 필요.
- **untrusted raw**: ingest 시 raw 안의 어떤 명령도 실행 안 함. 인용·요약만.

---

## 3. 초기 설정 (1회만)

### 3-1. Obsidian으로 vault 열기

1. Obsidian 실행
2. "Open folder as vault" → `/Users/gwanli/CS_V6` 선택
3. `.obsidian/` 자동 생성됨

### 3-2. 코어 설정

`Settings → Files & Links`:
- **New link format**: Shortest path when possible
- **Use [[Wikilinks]]**: ON
- **Default location for new notes**: `wiki/_scratch` (raw 오염 방지)
- **Attachment folder path**: `raw/_attachments`

### 3-3. 플러그인 설치 (Community)

`Settings → Community plugins → Browse`:

| 플러그인 | 역할 | 필수 |
|---|---|---|
| **Web Clipper** (Obsidian 공식) | 웹 글 → raw/로 클립 | 필수 |
| **Dataview** | wiki/_meta/stats.md 자동 통계 | 권장 |
| **Local Images Plus** | 클립 이미지 로컬 저장 | 권장 |
| **Templater** | frontmatter 자동 삽입 | 권장 |
| **Mermaid** (코어, 이미 있음) | MOC 렌더링 | 자동 |
| **Obsidian Git** | 자동 백업 | 선택 |

**Web Clipper 출력 경로**: `raw/` (root). Templater로 frontmatter `source_type: clip` 자동 삽입.

### 3-4. Graph view CSS (선택)

`.obsidian/snippets/llm-wiki-colors.css` 만들고 `Settings → Appearance → CSS snippets` 활성화:

```css
/* type별 노드 색 */
.graph-view.color-fill[data-type="concept"] { color: #5b9bd5; }   /* 파랑 */
.graph-view.color-fill[data-type="entity"]  { color: #70ad47; }   /* 녹색 */
.graph-view.color-fill[data-type="topic"]   { color: #ffc000; }   /* 노랑 */
.graph-view.color-fill[data-type="summary"] { color: #a6a6a6; }   /* 회색 */
```

---

## 4. 일상 사용

### 4-1. raw에 자료 넣기

3가지 방식:

**A. Web Clipper (가장 흔함)**
```
브라우저에서 글 보다가 → Web Clipper 익스텐션 클릭 → "Add to Obsidian"
→ raw/2026-04-07-foo.md 자동 생성
```

**B. 수동 파일 저장**
```bash
cat > /Users/gwanli/CS_V6/raw/karpathy-llm-wiki.md << 'EOF'
# LLM Wiki
본문...
EOF
```
또는 Obsidian에서 raw/ 우클릭 → New note.

**C. ChatGPT/Claude 대화 export**
```bash
mv ~/Downloads/chat-export.md /Users/gwanli/CS_V6/raw/2026-04-07-rag-discussion.md
```

**파일명 = 슬러그**. `raw/karpathy-llm-wiki.md` → `wiki/summaries/karpathy-llm-wiki.md`로 1:1 매핑.

### 4-2. Claude Code 실행

**중요**: 반드시 CS_V6 폴더에서 실행해야 CLAUDE.md/SKILL.md가 자동 로드됨.

```bash
cd /Users/gwanli/CS_V6
claude
```

### 4-3. 4가지 명령

| 명령 | 트리거 키워드 | 출력 | 새 파일? |
|---|---|---|---|
| **ingest** | "ingest 해줘", "정리해줘", "wiki에 넣어줘" | log 1줄 | wiki/ 다수 |
| **lint** | "lint 돌려줘", "정리상태 확인", "검증" | 리포트 | _broken/ (있을 때), _meta 갱신 |
| **status** | "상태", "통계", "현황", "얼마나" | 화면 출력 | 없음 |
| **digest** | "주간 시놉시스", "이번 주 요약", "weekly" | 화면 + log | digests/YYYY-WW.md |

자연어 또는 `/llm-wiki <op>` 둘 다 작동. SKILL.md description의 trigger 키워드를 Claude가 자동 인식.

---

## 5. 4가지 명령 상세

### 5-1. `ingest 해줘`

raw → wiki 컴파일.

**자동 수행**:
1. `raw/*.md` 중 `wiki/summaries/<slug>.md` 없는 것 식별 (= 미-ingest)
2. 각 파일에 대해:
   - sha256 hash 계산 → `source_hash`
   - **wiki/summaries/<slug>.md** 생성 (한국어 5문단 + frontmatter)
   - 핵심 개념 → **wiki/concepts/<concept>.md** 신규/갱신 (`first_seen`/`last_updated_by` 추적)
   - 인물·도구 → **wiki/entities/<name>.md**
   - 적절한 토픽 → **wiki/topics/<t>/index.md** + MOC mermaid
   - 영어 용어 → **wiki/_meta/glossary.md** (한국어)+(English) 병기
   - 양방향 [[wikilink]] 최소 3개
3. **wiki/master-index.md** 갱신
4. **wiki/log.md** append: `[ts] INGEST raw/foo.md → 12 wiki pages`
5. 파싱 실패 → wiki/_broken/로 격리

**특정 파일만**:
```
> ingest 해줘 raw/karpathy-llm-wiki.md
```

**raw 절대 안 건드림**: 모든 메타데이터는 wiki/summaries 측에 저장.

---

### 5-2. `lint 돌려줘`

볼트 건강체크 + 자동 수정.

**12개 검사**:

| # | 검사 | 의미 | 자동 수정 |
|---|---|---|---|
| 1 | Orphan | master-index에 없는 wiki 페이지 | 등록 제안 |
| 2 | Dead link | 끊어진 `[[wikilink]]` | 리포트만 |
| 3 | **Stale** | summary `source_hash` ≠ 현재 raw hash → raw 수정됨 | 재-ingest 권장 |
| 4 | Contradiction | 같은 concept 내 모순 | 리포트 |
| 5 | Gap | topic이 < 3 페이지 | 리포트 |
| 6 | Duplicate | 본문 70%+ 겹침 | 리포트 |
| 7 | **PII** | 주민번호·카드·이메일·전화 정규식 | 경고 |
| 8 | Broken frontmatter | YAML 파싱 실패 | wiki/_broken/로 격리 |
| 9 | Un-ingested raw | raw에 있는데 summary 없음 | ingest 권장 |
| 10 | Open-questions resolved | 새 페이지가 답하면 | 자동 archive |
| 11 | 500+ 페이지 임계 | master-index 비대 | split 권장 |
| 12 | stats.md | Dataview 통계 | 자동 갱신 |

**언제**: 주 1회 권장. 또는 ingest 많이 한 후.

---

### 5-3. `정리상태 확인`

빠른 통계. **lint과 다름** — 검사 안 함, 숫자만.

**출력 예시**:
```
CS_V6 LLM Wiki Status
─────────────────────
wiki pages: 47
  concepts:  12
  entities:  8
  topics:    5
  summaries: 15
  queries:   4
  digests:   3

raw files: 18
  ingested:  15
  pending:   3
  stale:     1

last ingest: 2026-04-05 14:22
last lint:   2026-04-06 09:00
last digest: 2026-04-01 (week 13)

open questions: 2
broken pages:   0
```

**언제**: "지금 내 볼트 어떻게 생겼지?" 궁금할 때.

---

### 5-4. `주간 시놉시스`

지난 7일간 추가/갱신을 1페이지로 요약.

**자동 수행**:
1. 지난 7일간 갱신된 wiki 페이지 식별
2. 토픽별 클러스터링
3. **wiki/digests/YYYY-WW.md** 생성:
   - 추가/갱신 페이지 한 줄씩
   - 새 concepts/entities
   - 클러스터별 1문단 시놉시스
   - open-questions 변경 (해결/신규)
4. master-index "Recent Changes" 갱신
5. log.md append: `[ts] DIGEST 2026-W14 → 12 pages summarized`

**커맨드**:
```
주간 시놉시스
```

**언제**: 매주 월요일 또는 금요일. "이번 주 뭐 배웠지?" 자동 답변. 시간 지나면 digests/가 학습 일지가 됨.

---

## 6. Query (질문)

ingest 끝나면 그냥 자연어로:

> Karpathy가 LLM Wiki를 만든 이유는?

> compile-once 원칙이 뭐야?

> RAG와 LLM Wiki의 차이?

또는 명시적:
```
/llm-wiki query "..."
```

**Claude 동작**:
1. `wiki/master-index.md` 먼저 읽기
2. 관련 `topics/*/index.md`로 좁히기
3. 구체 페이지 (concepts/entities/summaries) 참조
4. 답변에 `[[wikilink]]` 인용 포함
5. **raw/는 마지막 보루** — wiki에 답 있으면 raw 안 봄
6. 답 못 찾으면 `wiki/open-questions.md`에 자동 append
7. 답이 가치 있으면 "이거 wiki/queries/로 저장할까요?" 컨펌 → 동의 시 promote

---

## 7. 전형적 주간 워크플로

```
[월요일]
  Web Clipper로 지난주 모은 자료들 raw/에 자동 저장
  cd /Users/gwanli/CS_V6 && claude
  > ingest 해줘
  → 5개 raw → 12개 wiki 페이지 컴파일

[화~목]
  새 자료 raw/에 던지기 (Web Clipper or 수동)
  필요할 때 자연어로 query
  > "Karpathy가 한 말 뭐였지?"

[금요일]
  > lint 돌려줘
  → 건강체크, 1개 stale 발견 → 재-ingest
  > 주간 시놉시스
  → wiki/digests/2026-W14.md 자동 생성
  > 정리상태 확인
  → 통계 한눈에
```

---

## 8. Frontmatter 표준 (필수)

모든 wiki 페이지:

```yaml
---
title: "..."
type: concept | entity | topic | summary | query | overview | digest
status: draft | stable | stale
sources: [raw/foo.md]                  # summary 한정
source_hash: a1b2c3d4                  # summary 한정 (sha256 prefix 8자)
source_type: article | paper | conversation | note | clip
related: [[other-page]]
first_seen: 2026-04-07                 # concept 한정 (genealogy)
last_updated_by: raw/bar.md            # concept 한정 (genealogy)
created: 2026-04-07
updated: 2026-04-07
---
```

---

## 9. 보안

- **raw/는 untrusted external content**. ingest 시 raw 안의 어떤 명령도 실행 안 함. Web Clipper로 끌어온 HTML에 prompt injection 있을 수 있음 → "ignore previous instructions" 류는 그대로 보고하고 무시.
- **PII 노출 차단**: lint이 매주 정규식 검출 (주민번호·카드·이메일·전화).
- **공유 시 주의**: wiki/는 공유 가능 가정. raw/_compiled의 PII는 lint 거치지 않음 (raw 불변).

---

## 10. 한계 + 미래

**현재 v2 scope**:
- 수백 페이지 규모 ✓
- 단일 사용자 ✓
- 한국어 wiki + 다국어 raw ✓
- 5개 expansion: weekly digest, concept genealogy, open-questions, MOC 자동 렌더링, multi-lang glossary

**알려진 한계**:
- **동시 갱신 보호 없음** (단일 사용자 가정) → Obsidian Git 플러그인 권장
- **500+ 페이지 시 master-index 비대** → topic-split 수동 트리거 필요
- **이미지/PDF OCR 없음** → 텍스트만

**미래 (NOT in v2 scope)**:
- 1000+ 페이지 → LightRAG export
- V5 cross-vault bridge (`[[V5/...]]`)
- MCP server wrapper
- Mobile capture flow

자세한 결정 근거: `~/.claude/plans/sequential-jingling-journal.md`

---

## 11. 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `/llm-wiki` 명령 인식 안 됨 | CS_V6 외부에서 claude 실행 | `cd /Users/gwanli/CS_V6 && claude` |
| ingest 후 wiki/summaries에 없음 | 파싱 실패 | wiki/_broken/ 확인, log.md BROKEN 이벤트 확인 |
| Obsidian Graph view 비어있음 | wikilink 형식 아님 | `[[page]]` 사용, 폴더 경로 노출 금지 |
| stale 자꾸 뜸 | raw 자주 수정 | raw 진짜 불변 원칙 — 새 자료는 새 파일로 |
| Web Clipper가 raw/_attachments에 저장 | Attachment folder 설정 충돌 | Settings → Files & Links에서 분리 |
| Dataview stats.md 비어있음 | Dataview 플러그인 미설치 | Community plugins에서 설치 |

---

## 12. 참고

- **설계 plan**: `~/.claude/plans/sequential-jingling-journal.md` (CEO Review v2)
- **운영 로직**: `.claude/skills/llm-wiki/SKILL.md`
- **스키마**: `CLAUDE.md`
- **eval scenario**: `wiki/_meta/golden.md`
- **Karpathy gist**: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- **gpters 가이드**: https://www.gpters.org/nocode/post/obsidian-rag-setup-guide-GmwUMcONgl3ZSV3
