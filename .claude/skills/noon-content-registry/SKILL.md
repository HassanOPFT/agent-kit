---
name: noon-content-registry
description: >-
  Shared workflow for generating Noon's Saudi Grade 10-12 Math content
  (Questions, Slides, or Activities) in the Content Generation Registry —
  where Topics/Content Items/Prompts live in Notion, the pre-flight checks,
  Change log convention, and Status ownership. Use whenever a task touches
  the Notion "Content Generation Registry", a topic's page-range content, or
  any of the noon-slides-generation / noon-questions-generation /
  noon-activities-generation skills — read this one first, they assume it.
---

# Noon Content Generation Registry — shared workflow

**Canonical source:** [General Agent Prompt](https://app.notion.com/p/3a61593965aa810bab80ca3b3aea246f) in Notion, "Prompts" DB, `Prompt Type = General`. This file is a condensed, Claude-Code-local mirror of it — **fetch the live Notion page before generating real content**, this is a summary for quick orientation, not a substitute. If this file and Notion disagree, Notion is right; update this file to match (see "Keeping this in sync" below).

## Where things live

- **Topics DB** ("Math Curriculum — Topic Page Ranges & Curriculum IDs"): one row per textbook topic — Grade, Semester, Track, Chapter, Subsection, `Start Page`–`End Page`, `Book File`, and the curriculum IDs (`Grade ID`, `Subject ID`, `Chapter ID`, `Topic ID`).
- **Source PDFs**: local at `playground/content-generation/`, named per `Book File`. Also has `design-reference/reference-pages/` (Slides quality bar) and `design-reference/noon-characters/` (character sheet).
- **Content Items DB**: your output. **One row per Topic per Content Type** — never one row per question/slide/activity.
- **Prompts DB**: the type-specific instructions — see [[noon-slides-generation]], [[noon-questions-generation]], [[noon-activities-generation]].

## Workflow

1. Pick a Topic row.
2. **Pre-flight**: confirm the `Book File` PDF exists locally, `Start Page`–`End Page` are within the PDF's actual page count, and no Content Item already exists for this Topic + Content Type (if one does, reopen and append rather than duplicating).
3. Read the source pages — the **entire** `Start Page`–`End Page` range, not a sample of it.
4. Read the active type-specific prompt in Notion.
5. Generate, then create/update one Content Item: `Topic` relation, `Content Type`, `Prompt Used` relation, page body, `Import Payload`, `Covers`, `Status = Generated`.
6. Stop. A reviewer moves it forward from there.

## Global rules (every content type)

- **Textbook fidelity** — ground everything in the actual source pages, never generic knowledge of the topic.
- **Coverage over minimalism** — no fixed count per topic. Generate as much as the source pages actually support; don't cap coverage to hit a "reasonable" size, and don't pad with invented content either. This is the rule that prevents count-driven generation (see [[noon-slides-generation]] for what it looks like when this is skipped).
- **Cognitive load / step-by-step** — chunk information, reveal worked solutions progressively.
- **Arabic terminology** — match the Topic's own Chapter/Topic naming, don't introduce alternate translations.
- Never guess curriculum IDs — pull them from the linked Topic row.
- `Import Payload`: prefix JSON values with `JSON: ` (Notion API quirk — valid JSON on its own silently mis-parses). CSV payloads (Questions) don't need this prefix.

## Status ownership

- **You**: only ever set `In Progress` or `Generated`.
- **Reviewer**: owns `Needs Revision`, `Ready for Import`, `Created in System`, `Deployed Link`. Never set these yourself.

## Change log

Every Content Item's page body ends with `## Change log` — newest entry first, one line per change: what changed, why, and any prod id affected (lesson/library/version). Absolute dates only (`2026-08-19`, never "today"). Record real outcomes, including partial/unfixed ones — don't omit failures.

**If reviewer feedback exposes a flaw in a prompt itself** (not just one topic's content), fix the prompt too and note it in the log — otherwise the same defect regenerates on every future topic. This is exactly what happened with the Slides Prompt's page-coverage rule — see [[noon-slides-generation]].

## Keeping this in sync

This skill (and its three siblings) mirror the four active rows in Notion's `Prompts` DB. Each Notion prompt page carries a matching pointer back to its skill file. When either side changes:
- Edited the Notion prompt? Update the matching skill file's condensed summary in the same sitting.
- Edited a skill file with a real process/rule change (not just local pipeline notes)? Push the same change to the Notion page and bump its `Version` property.
Don't let a fix land on only one side — that's the out-of-sync state this cross-referencing exists to prevent.
