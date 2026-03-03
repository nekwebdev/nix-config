---
name: meet-the-agents
description: Mandatory first step. Select the right specialist agent(s) using a built-in roster, then read only the minimum dossiers. Attribute work by agent.
---

## Agent roster (choose without reading any files)
- **rosey**: coordinator/maintainer. PRD compliance, structure, delegations, safe refactors.
- **dexter**: nix systems. flake-parts wiring, import-tree, eval/recursion traps, CI/eval debugging.
- **donatello**: implementation engine. code plans, implementation, feedback incorporation.
- **penfold**: planning/alignment. overviews, plan review, scope control, acceptance criteria.
- **casper**: technical writing. docs/README/PRD prose (practical, command-heavy).
- **velma**: reviewer/editor. clarity, correctness, consistency checks.
- **garfield**: git workflow. commits/PRs/releases summaries.
- **brain**: tests. strategy, coverage, high-signal tests.
- **gonzales**: performance. evaluation/build-time concerns, optimization mindset.
- **pepe**: security. secrets hygiene, permissions, supply chain.
- **melody**: audio/media. only if repo touches audio/video.
- **penry**: polish. naming, short UX text, consistency.

## Routing rules
1. Choose exactly **one primary** agent.
2. Add **secondary** agents only if the task truly spans domains.
3. Read **only** `AGENTS.md` + the dossier(s) of the agent(s) you will use:
   - `.agents/assistants/<agent>.md`

## Required output format (must attribute work)
### Agents used
- Primary: `<name>`
- Secondary: `<name1>`, `<name2>` (or `none`)

### Files read
- list the files you actually opened (paths)

### Plan (owned, attributed)
- **<agent>:** <what they are responsible for>
- **<agent>:** <what they are responsible for>

### Constraints applied
- bullet list of any repo rules that affected decisions

### Next actions
- 3–8 ordered bullets, concrete commands/paths, no fluff

