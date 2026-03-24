# AGENTS.md

## Mandatory workflow
- Always start with the `meet-the-agents` skill.
- Use one or more specialist agents as needed, but **only read the agent dossier(s) you actually use**.
- Attribute work by agent name (who did what).

## Repo constraints (PRD)
- platform: **x86_64-linux only**
- platform enforcement: flake outputs/checks must target `x86_64-linux` only
- composition: **flake-parts** is core to the design pattern
- module loading: **import-tree** recursively loads the `modules/` tree
- architecture: keep a lean baseline (`lotus` host + baseline user module) and extend with scaffolding boilerplate
- composition model: host module explicitly imports NixOS modules; user module explicitly imports HM modules
- HM integration: through NixOS only (no standalone HM output path)
- rule: **HM-first** (if it can be Home Manager, it must be Home Manager)
- HM-first exceptions (allowed in NixOS modules): boot/kernel/hardware, filesystems, networking/firewall, users/groups, PAM/sudo/polkit, root-owned services
- users policy: host-declared users are normal users and must include `wheel`
- VPN convention: put user-supplied `.ovpn` files in `~/.config/ovpn/`; `policy.nix` imports them at runtime via `vpn-profile-import`
- wrapped programs: use **wrappers** only (do not use `wrapper-modules`)
- formatting: **treefmt-nix** (Nix formatter: **alejandra**)
- runner: **justfile** calling `/scripts/*.sh`

## Commands
```bash
just help
just fmt
just check
just check-vm
just switch host=<host>
just new-user user=<user>
just new-host host=<host> user=<user>
```

## Agent roster (quick routing)
- **rosey**: coordinator/maintainer. PRD compliance, structure, safe refactors, delegating to specialists.
- **dexter**: nix systems. flake-parts wiring, import-tree, module evaluation, recursion traps, CI/eval debugging.
- **donatello**: implementation engine. makes concrete code plans, implements changes, incorporates review feedback.
- **penfold**: planning/alignment. creates overviews, reviews plans for completeness and coherence, checks scope drift.
- **casper**: technical writing. docs, READMEs, PRDs, blog-style prose (adapt to repo tone as required).
- **velma**: reviewer/editor. clarity, correctness checks, consistency, "does this actually match the repo rules".
- **garfield**: git workflow. PR descriptions, conventional commits, changelog-style summaries.
- **brain**: testing. test strategy, coverage review, "what should be tested and how".
- **gonzales**: performance. profiling mindset, hotspots, avoiding expensive evaluation, build/time concerns.
- **pepe**: security. secrets handling, permissions, supply-chain hygiene, "don't do dumb stuff".
- **melody**: audio/media. only relevant if repo touches audio/video tooling; otherwise rarely used.
- **penry**: UX/wording polish. short, friendly UI text, user-facing instructions, naming consistency.

## Hard rules
- keep `flake.nix` thin (inputs + `mkFlake` + `import-tree ./modules`)
- keep module exports in `modules/*` (`flake.nixosModules.*`, `flake.homeModules.*`, `perSystem.packages.*`)
- add new hosts/users via scaffolding scripts first, then edit generated modules
- do not reintroduce toggle-file/module-ID/unique-group policy frameworks unless PRD is explicitly updated
- do not reintroduce standalone HM outputs unless PRD is explicitly updated
- do not use `wrapper-modules` in this repo unless PRD is explicitly updated
- keep logic out of `justfile`; scripts live in `/scripts`
- do not run `just switch` on this already-configured machine during validation; use `just check` + `just check-vm`
- commit and review `flake.lock` input updates intentionally; do not drift input versions accidentally
- do not commit secrets (tokens, private keys, machine-specific credentials) to tracked files

## Merge gates (required)
- run `just fmt` before merge
- run `just check` before merge
- run `just check-vm` before merge

## Test expectations
- any new/changed module must keep evaluation passing under `just check`
- host or user scaffolding changes must include `just check-vm` verification notes

## Extending `.agents`
- New assistants are supported in this repo.
- To make a new assistant routable, add `.agents/assistants/<name>.md`, add the assistant to the roster above, and add the assistant to `.agents/skills/meet-the-agents/SKILL.md`.
- Keep assistant domains distinct; do not add near-duplicates of existing roles without a clear repo-specific gap.

## Reminders
- Never run git commands that would write to the repo directly without asking.
- Always use the fish style for bash commands.
- Flake-evaluating Nix commands (`nix build`, `nix develop`, `nix run`, `nix check`, `nix flake show`, `nix flake check`) read from Git's index, so new or changed files must be staged first or you can get confusing "file not found" errors.
- No commit is needed; `git add -A` (or `git add <paths>`) is enough.
