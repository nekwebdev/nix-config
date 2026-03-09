---
name: commit
description: Inspect staged git changes and output one copy-ready commit message in a single code block.
---

## Purpose
Generate a commit message from currently staged changes only.

## Steps
1. Confirm we are in a git repository.
2. Read staged changes only:
   - `git diff --cached --name-status`
   - `git diff --cached --stat`
   - `git diff --cached`
3. Infer the primary intent and produce one conventional commit message.

## Output rules
- Output exactly one fenced code block and nothing else.
- The block must be copy-ready for `git commit -m`/editor usage.
- If nothing is staged, still output one code block stating no staged changes were found.
- Never run `git commit`.
