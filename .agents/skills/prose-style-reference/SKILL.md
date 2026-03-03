---
name: prose-style-reference
description: Use this before drafting or rewriting documentation. Reads only the minimum writing/review agent dossiers and produces PRD-aligned prose.
---

## Purpose
Apply the repo's prose guidance using the writing-focused agents, without loading unnecessary context.

## Steps (minimal context)
1. Read `AGENTS.md` for repo constraints and tone rules.
2. Read `.agents/assistants/casper.md` (writer) and/or `.agents/assistants/velma.md` (editor) depending on the task:
   - drafting new docs -> casper (primary), velma (review)
   - tightening existing docs -> velma (primary), casper (optional)
3. Write the content in the requested format, using concrete commands/paths and keeping it PRD-aligned.

## Output rules
- keep structure readable (headings + bullets)
- prefer explicit commands and file paths
- avoid scope creep: don't invent folders/features not in PRD

