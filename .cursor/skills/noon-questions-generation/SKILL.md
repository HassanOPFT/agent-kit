---
name: noon-questions-generation
description: >-
  Generate Noon Math practice questions for a topic as a bulk-import CSV
  (MCQ/OPEN_TEXT), mapped to textbook exercise sections (تحقق من فهمك،
  تأكد، تدرّب، مهارات التفكير العليا). Use for any task producing new
  questions for the Question Bank, or auditing/fixing existing bank
  questions' correctness or coverage for a topic.
---

# Noon Questions generation

**Canonical source:** [Questions Prompt](https://app.notion.com/p/3a61593965aa8140ab95d645be77068e) in Notion (v16 as of 2026-09-02). Read [[noon-content-registry]] first for the shared workflow. **Fetch the live Notion page before generating real content** — this is a condensed orientation summary, not a substitute.

## Target: bulk CSV import

One Content Item row per topic. CSV header + one row per question, imported via `POST /questions/bulk-generation`. Columns: `type` (`MCQ` or `OPEN_TEXT` only), `question_text`, `topic_ids`, `subtopic_ids`, `concept_ids`, `difficulty` (1-5), `exam_paper` (leave blank, open/deferred — flag if the topic feeds an exam-paper-gated template), `a`/`b`/`c`/`d`, `correct_answer_a/b/c/d` (`true`/`false`, exactly one `true` unless multi-select), `explanation`, `grading_instruction` (OPEN_TEXT only), `shuffle_choices`, `is_multi_select`.

Other question types (annotation, match, categorize, order, fill-blanks, image-hotspot) aren't bulk-importable — note them as one-off `QuestionRequestDTO` JSON for the single `POST /questions` endpoint instead.

## Purpose → textbook section → difficulty

| Purpose | Source section | Difficulty |
|---|---|---|
| Section Check | تحقق من فهمك | 1-2 |
| Your Turn | تحقق من فهمك | 2-3 |
| Exit Ticket | تأكد | 2-3 |
| Homework | تدرّب | 3-4 |
| Challenge / HOT | مسائل مهارات التفكير العليا | 4-5 |

Pull the actual exercise from the matching section — don't invent unless that section is genuinely missing/insufficient. No cap of one question per purpose: include every usable item from the source, and before finalizing, recount the section's exercises against what you generated — if the source has more than you included, go back and add the rest.

## Two rules that are easy to skip

- **Answer-position spread**: don't default the correct choice to column `a`. Across a topic's questions, the correct answer should land in `a`/`b`/`c`/`d` at roughly similar rates — no column over ~half. `shuffle_choices: true` is a runtime flag, not a substitute; a reviewer reading the raw CSV sees the literal order.
- **Question-type diversity**: most activity types accept any question type, but open-response activities only pull `OPEN_TEXT`, annotation only pulls `ANNOTATION`, drag-and-drop only pulls `MATCH`/`CATEGORIZE`/`ORDER`/`FILL_BLANKS`/`IMAGE_HOTSPOT`. All-MCQ coverage leaves zero eligible questions for those. Generate at least one non-MCQ when the content naturally supports it.

## Figures: a question that references a figure must have one

The CSV has no image column, so nothing about the import step forces this — a question whose stem says «في الشكل» / «من الشكل» / «الشكل المقابل» imports perfectly happily with no figure attached and reads as broken to the student. Reviewers have already been hand-attaching figures to our questions after the fact (11 of one topic's 17 were fixed this way by someone else). Generate them instead.

Attaching is a second pass, after import, because a figure has to bind to a question id and the ids don't exist until the CSV lands:

1. Write `noon-slide-publish/figures_<topicId>.py` — `FIGURES = [(question_id, choice_index_or_None, basename, prompt), ...]`.
2. `generate_question_figures.py --topic-id X --output-dir out/figures_X --dry-run` → eyeball every PNG.
3. Drop `--dry-run` to upload and attach.

Under the hood: `POST {filesUrl}/upload` (multipart, field `fileUpl`, 10MB cap) returns four sized CDN urls; the question then takes `medium_url` — the size the admin panel itself picks — via `PUT /questions/{id}` with the whole question body (read-modify-write; a field you omit is a field you delete). `filesUrl` is prod `https://files.studyatnoon.com`, a different service from noon2_core but the same auth headers.

Two things worth knowing:

- **A choice can carry its own figure** (`choices[i].url`), not just the stem (`url`). That's the only way to write "which diagram shows…" questions, and the CSV cannot express it at all — it's figure-pass-only.
- **Question figures are not slides.** They render a few hundred pixels wide next to the choices. `question_figure_style.py` holds the prompt shell: white background, black line art, no character, no title, no restatement of the stem, 4:3, padded not cropped (cropping cuts the edge labels off, which is the whole point of the figure). Don't reuse the slide style here.

## Math goes in MathML, never bare Unicode

Question text in the bank is HTML, and the apps split it on `<math>…</math>` and rasterise every match through Wiris. An expression written as literal Unicode inside an Arabic sentence is instead laid out by bidi — which is where `−2` becomes `(2-)`, `t = 0.75 h` loses its unit to the next line, and `(0.5, 500)` comes out reversed. All three were reported on live lessons. A rasterised formula cannot be reordered, so the fix is to stop emitting bare Unicode.

Applies to `question_text`, `a`–`d`, and `explanation`. `grading_instruction` is read by a grader, not rendered, so it's exempt.

Author with `$…$` delimiters and run [mathml.py](../../noon-slide-publish/mathml.py):

```
render_inline("الزاويتان $∠3$ و $∠4$ متقابلتان، و $m∠3 = (6x + 2)°$.")
```

Explicit delimiters, not prose sniffing — `x` and `m` are ordinary Arabic-sentence characters too, and guessing wrong silently corrupts the sentence.

Then gate the CSV on `validate_mathml.py out/questions/<topicId>.csv`, which renders every fragment through Wiris and flags any symbol left outside a `<math>`. Malformed MathML does **not** fail the import — it fails at read time, as a missing image in front of a student.

Verified against prod (2026-09-02):

- `POST /questions/bulk-generation` **preserves inline MathML** from a CSV cell — probed with a throwaway row, read back intact, deleted. No post-import pass needed.
- `POST /noon2-core/wiris/formula-render` **cannot validate** — it only hashes the markup and returns the CDN path plus an S3 presign, answering 200 for nonsense. Validation must go to `https://www.wiris.net/demo/editor/render` (form body `mml`/`centerbaseline`/`autozoom`/`dpi`), the renderer the apps fall back to.

Point names split into one `<mi>` per letter (`<mi>A</mi><mi>C</mi>`, matching the bank's existing rows) — a single two-letter `<mi>` typesets with no gap and reads as a product. Symbols are numeric entities (`&#8736;` ∠, `&#8773;` ≅, `&#8741;` ∥, `&#176;` °), never literal glyphs.

**Existing questions were not backfilled** — this is for new questions from 2026-09-02 on, unless someone explicitly asks for a backfill.

## Never modify a question we didn't generate

Check `creatorId` first (`GET /questions/{id}`; ours is `666284`). The lesson template auto-pulls any topic-tagged question from the shared bank, so most questions *inside* our lessons belong to other authors — every wrong answer key reviewers have flagged so far was in one of those. Editing it would silently change that question for every other lesson using it. `attach_question_image()` enforces this and refuses. When a reviewer flags one, say in the thread that we didn't generate it and won't modify it, and leave it to the content team.

## Formatting (page body)

CSV block first (fenced, labeled "Import Payload (CSV — bulk-generation, N rows)"), then readable Q&A below it: heading per purpose, question text, **each choice on its own bullet line** (never `|`/comma-inline), `**الشرح:**` on its own line, two blank lines between questions.

`Import Payload` property gets the same CSV — no `JSON: ` prefix needed here (that workaround is only for payloads that look like JSON, e.g. Slides/Activities). If the CSV is too large for the property (~15+ rows for Arabic sets), keep it in the page body only and say so — never truncate to fit.

After import, add a "Questions in the Question Bank" table at the end: id (linked to `https://admin.noonacademy.com/dashboard/question-bank/{id}`), type, difficulty, short excerpt.

## A gotcha not in the prompt (found operationally)

A bank question's `correctChoiceId` is not guaranteed correct — two verified-wrong ones surfaced this session while sourcing replacement questions for a lesson (topics 25134, 25139). Re-derive the answer from the math yourself before trusting or reusing an existing bank question, same as the prompt's own audit item 1 already says to do for questions you write yourself.

## Keeping this in sync

See [[noon-content-registry]]. If you change a rule here, push it to the Notion Questions Prompt page too and bump its `Version` — and vice versa.
