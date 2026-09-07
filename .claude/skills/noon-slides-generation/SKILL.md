---
name: noon-slides-generation
description: >-
  Generate or fix Noon Math lesson slide decks — writing a deck_<topicId>.py
  spec, generating images via the noon-slide-publish Python pipeline
  (OpenRouter/gemini image-gen), publishing/updating a live lesson, and
  fixing reviewer slide-comments. Use for any task involving lesson slides,
  the noon-slide-publish pipeline, deck_*.py files, Image Library records,
  or a lesson's image content on admin.noonacademy.com.
---

# Noon Slides generation

**Canonical design/content source:** [Slides Prompt](https://app.notion.com/p/3a61593965aa8122b6b2d032f9001e71) in Notion (v23 as of 2026-09-02). Read [[noon-content-registry]] first for the shared workflow this assumes. This file adds the concrete operational knowledge for doing the work in `playground/noon-slide-publish/` — a Python pipeline that reaches the same end state as the Notion prompt's manual flow (deck of 960×540 images → one Image Library record per topic → live lesson) but via `generate_deck.py` + OpenRouter image-gen + direct admin API calls, instead of hand-authored SVG + manual upload.

## The rule that matters most: coverage is exhaustive, not representative

**Before writing a single slide, list every postulate/theorem/named worked example in the topic's full `Start Page`–`End Page` range** (from the Notion Topics table — that page range is the coverage contract). Don't stop once the deck *feels* complete (title, objectives, hook, a couple of concepts, one or two examples, summary) — that's how content silently goes missing. This bit twice in one session:

- **25137/25138 decks** (this session): first pass targeted a slide count matching sibling decks (~12), skipping real content — user caught it: *"we should generate slides that cover the topics given the content."* Fix: re-read the source pages, listed every postulate/theorem/example, rebuilt to 14-15 slides driven by content, not count.
- **25134 deck** (pre-existing, found during this session's debug): covered only pp.66-67 of an assigned 66-73 range — the Vertical Angles Theorem (1.8) and the right-angle postulate table (1.9-1.13) were never added, because the original deck stopped once it had "enough" for a lesson shape. The tell: the book's own stated objectives for the topic ("زوايا متطابقة وزوايا قائمة") named content the deck never touched.

This is now also audit item **1b** in the Notion Slides Prompt — check it explicitly before calling a deck done.

## Pipeline files (`playground/noon-slide-publish/`)

- `.env` — config incl. `NOON_CORE_BASE_URL`, `ADMIN_ACCOUNT_ID` (ownership guard for deletes).
- `slide_style.py` — shared visual language (`STYLE` constant, `build_prompt()`), matches the Notion prompt's chalk theme/anatomy. Don't restate style rules per-slide; only per-slide content.
- `deck_<topicId>.py` — one file per topic: `TOPIC_ID`, `SUBJECT_ID`, `CHAPTER_ID`, `TITLE`, and `SLIDES = [(stage, basename, pose|None, body_prompt), ...]`. `pose` is one of `hook`/`concept`/`withholding`/`engagement`/`reveal-summary`/`reveal-confirm`/`comparing` (only set it when the body text describes the Noon character).
- `generate_deck.py --topic-id N --output-dir out/N_vX [--only base1,base2]` — generates images via OpenRouter (`google/gemini-3.1-flash-image`), writes `out/<dir>/raw/` and normalized 960×540 PNGs to `out/<dir>/`. `--only` regenerates a subset — always use it when fixing specific slides, don't regenerate the whole deck.
- `publish_deck.py --topic-id N --images-dir out/N_vX --new-lesson` — first-time publish: builds PDF → uploads Image Library → creates lesson → calls `concept_coverage` template's `generate` (auto-populates Section Check/Game/Exit Ticket from the topic's existing question bank — **this pipeline does not author questions**, it relies on curriculum-tagged bank coverage already existing; check with `GET /questions?topic_id=N&page=0&size=100` before publishing, snake_case params only).
- `update_lesson_slides.py --topic-id N --lesson-id LESSON_x --images-dir out/N_vX` — full-deck swap on an existing live lesson: uploads new library under a `— pending` title, PUTs every slide's `imageUrl`, deletes the old library, renames the new one to the canonical `{title} — شرائح` (no version suffixes — that was the old convention, now cleanup debt if you see one). **Requires `len(deck.SLIDES) == current live image-slide count`** — if you're inserting/removing slides, do that first (see below), then run this.
- `noon_client.py` — `delete_image_library()` (ownership-guarded against `ADMIN_ACCOUNT_ID`, the only delete path in the codebase — never bypass it), `reply_to_comment_thread()` / `resolve_comment()` for slide comments, `upload_slide_deck()`, `create_lesson()`, `generate_lesson()`.

## Inserting or removing a slide from a live lesson

`update_lesson_slides.py` only swaps images 1:1 — it can't change slide *count*. To insert (e.g. adding a missing worked example mid-deck):
1. Build a small PDF of just the new image(s) (`pdf_builder.build_slide_deck_pdf`), upload as a **throwaway** Image Library (`upload_slide_deck`, temp title), poll `find_library_id_for_topic`.
2. `POST /admin/lessons/{lessonId}/slides/image` with `{"imageGroupId": <temp library id>, "sourceSegmentId": <segment id from GET .../segments>, "slideIndex": <insert position>}` — inserts all pages of that library as new slides at that index, shifting everything after it back. (Endpoint traced from `noon2-frontend/packages/common/src/requests/slide/{Api,Types}.ts` — no wrapper exists in `noon_client.py` yet.)
3. Delete the temp library (safe — slides store the CDN `imageUrl` directly, not a live reference to the library, same assumption `update_lesson_slides.py` already relies on).
4. Now `len(deck.SLIDES)` matches the live count again — run `update_lesson_slides.py` normally to consolidate everything back into one canonical library.

There's no delete-slide wrapper here yet; the frontend's `deleteAdminSlide` is `DELETE /admin/lessons/{lessonId}/slides/{segmentId}/{sessionSlideId}` if it's ever needed.

## Image-gen defect patterns (checked every slide, every time)

The model (`gemini-3.1-flash-image`) is unreliable in specific, recurring ways. **Zoom-crop and read every generated slide before shipping** — don't eyeball a thumbnail. Recurring failures and their fixes:

- **Hallucinated text/numbers bleeding in from nowhere** (e.g. a random `m∠2=56°` or a stray `0123456789` digit string appearing on an unrelated slide) — add an explicit closed-world instruction: *"X and Y are the ONLY elements inside the card. Nothing else — no extra sentence, no digit string, no leftover text from any other problem."* Naming the specific intrusion category that keeps showing up (angle measures, in one deck) and banning it explicitly worked better than a generic "no extra text."
- **Negative numbers embedded in Arabic prose corrupt** (e.g. `−2` becomes `2 − 2`, or a coordinate's sign attaches to the wrong number) — isolate the number on its own line/expression rather than inline in a sentence, or spell it out (`سالب 2`) with an explicit digit-by-digit re-check instruction. Numbers as standalone LTR math islands are reliable; numbers woven into RTL prose are not.
- **Word/label duplication at a line wrap** (a word like `ميله` or `التكلفة` printed twice because the line wrapped) — add "written exactly once, even across a line wrap" plus a count check.
- **Stacked instructions can themselves cause new corruption** — piling on more and more CRITICAL/COUNT-CHECK clauses on the same slide once made the model render the literal word "OUTSIDE" as visible text (parroting the instruction language back as content). If a fix introduces a new defect, don't add a fourth clause — simplify back down first.
- **The "COUNT CHECK: exactly N pieces of text, list them" phrasing** is the single most reliable anti-hallucination pattern found this session — more effective than "don't add extra text." Prefer it for any slide with sparse content (title, objectives) where the model tends to fill perceived empty space.
- **Cross-check text against the diagram, not just against the prompt** — a coordinate or label can be correct in the prose line but wrong in the figure (or vice versa), independently, since they're rendered together but not internally cross-validated by the model.

## Question bank checks (real API gotchas, not in the Notion prompt)

- `GET {base}/questions` — **query params are snake_case** (`topic_id`, not `topicId`/`topic`). Wrong casing is silently ignored and returns the latest 10 questions regardless of filter — looks like it worked, didn't.
- `GET {base}/questions/{id}` works; `GET {base}/admin/questions/{id}` 404s.
- A question's `correctChoiceId` in the bank is not guaranteed correct — verify the math yourself before reusing a bank question as a replacement (two verified-wrong `correctChoiceId` flags were found in the 25134/25139 bank this session).

## Keeping this in sync

See [[noon-content-registry]]'s "Keeping this in sync" section. This file mirrors the Notion **Slides Prompt** specifically — its design/composition/audit rules are condensed above under "The rule that matters most" and implicitly assumed elsewhere; the pipeline/gotcha sections below that line are Claude-Code-local knowledge with no Notion equivalent (they don't need to be pushed there). If you change a *content/design* rule (not a pipeline mechanic), push it to the Notion page too and bump its `Version`.
