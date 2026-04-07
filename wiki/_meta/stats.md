---
title: "Vault Stats"
type: overview
status: stable
created: 2026-04-07
updated: 2026-04-07
---

# Vault Stats

> Dataview 플러그인이 자동으로 채운다. 플러그인 없으면 빈 결과.

## Type별 페이지 수

```dataview
TABLE length(rows) AS "count"
FROM "wiki"
WHERE type
GROUP BY type
```

## raw 파일 수

```dataview
LIST FROM "raw"
WHERE !contains(file.folder, "_attachments")
```

## Stale 페이지 (90일+ 미수정)

```dataview
LIST FROM "wiki"
WHERE updated AND date(updated) < date(today) - dur(90 days)
SORT updated ASC
```

## Recent ingest (최근 7일)

```dataview
TABLE source_hash, source_type, created
FROM "wiki/summaries"
WHERE created AND date(created) >= date(today) - dur(7 days)
SORT created DESC
```

## Open questions 수

```dataview
LIST FROM "wiki/open-questions"
```
