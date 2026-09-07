---
name: noon-activities-generation
description: >-
  Design (spec only, not build/deploy) a Noon interactive (Nolt) activity
  for a Math topic — the interaction design and its CreateNoltActivityRequest
  draft payload. Use for tasks producing a new activity spec for the
  Content Generation Registry.
---

# Noon Activities generation

**Canonical source:** [Activities Prompt](https://app.notion.com/p/3a61593965aa81258520dba8461d38da) in Notion (v3 as of 2026-09-02). Read [[noon-content-registry]] first for the shared workflow. **Fetch the live Notion page before generating real content** — this is a condensed orientation summary, not a substitute.

## Scope: generation only

This produces a **spec**, not a live activity — you do not build, deploy, or register it. `Status` stops at `Generated`; `Deployed Link` and `Status = Created in System` are set later, outside this flow, by whoever actually builds and deploys it.

## Design rules

- **Step-by-step reasoning** — reveal the interaction progressively, never the full answer/process at once.
- **Concept linking** — if the topic builds on a prior one in the same Chapter (check sibling Topics), open with a comparison/concept-map interaction connecting them.
- **Cognitive load** — one core interaction per activity; don't combine unrelated concepts.
- **Textbook fidelity** — base content/data on the topic's actual source pages, not generic knowledge.

## What to produce

1. **Generated Content** (page body): what the activity teaches, its interaction type (drag-drop, simulation, quiz-style, etc.), and how it reinforces this specific topic — specific enough that someone else could build it from the spec alone.
2. **Import Payload** — draft `CreateNoltActivityRequest` JSON (`JSON: ` prefix per the Notion property quirk, per [[noon-content-registry]]):
   ```json
   {
     "noltId": "string, unique, URL-safe slug, max 255",
     "activityName": "string, max 255",
     "activityDescription": "string, optional",
     "isPublished": true,
     "curriculums": [{ "subjectId": 0, "chapterId": 0, "topicId": 0 }]
   }
   ```
   `noltId` as a proposed descriptive slug including grade/chapter/topic hints to avoid collisions (e.g. `math-g10-ch1-inductive-reasoning`); `curriculums[0]` fields from the Topic row.
3. Set `Status = Generated` and stop.

## Keeping this in sync

See [[noon-content-registry]]. If you change a rule here, push it to the Notion Activities Prompt page too and bump its `Version` — and vice versa.
