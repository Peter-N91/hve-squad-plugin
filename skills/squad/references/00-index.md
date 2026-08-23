---
name: squad-reference-index
description: "Which squad reference file to read for which job, plus the companion hooks.json rules that back the squad's deterministic enforcement in this plugin distribution."
license: MIT
metadata:
  authors: "Peter-N91/hve-squad"
  spec_version: "1.0"
  last_updated: "2026-08-14"
---

# Squad Reference Index

Read this file first, then read only the reference files your role names in its Skill Reference Contract. A reference file is loaded whole, so reading one you do not need costs attention you need elsewhere.

## Which file for which job

| File                                               | Read it when                                                              |
|----------------------------------------------------|---------------------------------------------------------------------------|
| [floor.md](floor.md)                               | The unconditional squad floor: state paths, single-writer rule, dispatch discipline, proof of dispatch, the literal consumption block |
| [profiles-and-packs.md](profiles-and-packs.md)     | Seeding or amending a roster: profile choice, packs, which roles exist    |
| [operating-procedure.md](operating-procedure.md)   | Running a turn: Init, Route, ledger reconciliation, Decide, Handoff       |
| [gates-and-modes.md](gates-and-modes.md)           | Gates — discovery, intake, council, implementation, routing table — and autonomy modes |
| [federation.md](federation.md)                     | The squad root is a federation: layout, precedence, federation modes      |
| [notifications-and-watch.md](notifications-and-watch.md) | Approval-channel capture, remote/notification delivery, and Watch Mode (event-driven autopilot triggers) |
| [scribe-procedure.md](scribe-procedure.md)         | Writing squad state, Scribe only: every payload-to-step rule and contract |
| [entry-schemas.md](entry-schemas.md)               | Any ordinary write turn: decision and verdict entries, history, state.json |
| [seed-templates.md](seed-templates.md)             | Stamping first-run state, Init only: `team.md` and `routing.md`           |
| [consumption.md](consumption.md)                   | Recording or estimating cost: ledger templates and the estimator          |
| [federation-templates.md](federation-templates.md) | Creating or expanding a federation: registry, meta-routing, root files    |
| [mcp-capability.md](mcp-capability.md)             | A dispatched role needs an external tool: which MCP to prefer and the named fallback when it is absent |

The Scribe reads `00-index.md`, `scribe-procedure.md`, and `entry-schemas.md` on every turn, and reads `consumption.md`, `seed-templates.md`, and `federation-templates.md` only when the turn's payload writes their files. The coordinators read `seed-templates.md` and `federation-templates.md` only to verify deliverable roots during Init or a federation change.

## Companion hook rules

In the plugin distribution, the squad's deterministic enforcement rules ship as `hooks.json` at the plugin root instead of `applyTo`-scoped `.instructions.md` files. `hooks.json` entries run as real shell scripts under `hooks/scripts/`, invoked by the host on `sessionStart`, `preToolUse`, `postToolUse`, `subagentStop`, and `userPromptSubmitted` — see `hooks/README.md` for exactly what each one checks, what it cannot check, and why. In summary:

* **`impactful-action-gate`** (`preToolUse`, matcher `bash|powershell`) — denies a shell command matching the Impactful-Action Gate's trigger list (`git push`, `terraform apply`, `az ... create|delete`, `gh pr merge`, destructive infra/data ops) without explicit human confirmation. Backs [gates-and-modes.md](gates-and-modes.md)'s Autopilot Procedure and [notifications-and-watch.md](notifications-and-watch.md)'s Watch Mode Unattended Gate Disposition.
* **`state-write-guard`** (`preToolUse`, matcher `create|edit`) — denies a full-overwrite of an existing append-only squad-state file (`decisions.md`, `notifications.md`, `federation.md`, `history/*.md`). Backs [floor.md](floor.md)'s single-writer/append-only rule. **Cannot** verify the calling agent is the Squad Scribe — `preToolUse` payloads carry no caller identity.
* **`dispatch-guards`** (`preToolUse`, matcher `task`) — three checks on a subagent dispatch: the Intake Readiness Verdict gate, the Tracker-Write Gate (only `Squad Backlog Executor` may dispatch a tracker write), and the federation sub-squad naming rule (`^[a-z0-9][a-z0-9-]*$`). Backs [gates-and-modes.md](gates-and-modes.md)'s Intake Gate and Implementation Gate procedures and [federation.md](federation.md)'s naming rule.
* **`session-start-check`** (`sessionStart`) — informational only: reports whether squad state resolves (single squad vs. federation vs. uninitialized) and whether `state.json` parses. Backs [floor.md](floor.md)'s state-path resolution rule; cannot block.
* **`autonomous-escalation-check`** (`subagentStop`) — scans a completed subagent's own response for a Stop verdict, a `Risk: High` finding, a compliance violation, or irreversible-write language, and forces an escalation instead of a silent continuation. Backs [gates-and-modes.md](gates-and-modes.md)'s Autonomous Procedure mandatory triggers.
* **`notification-audit`** (`postToolUse`, matcher `bash|powershell`) and **`prompt-injection-note`** (`userPromptSubmitted`) — log-only backstops for [notifications-and-watch.md](notifications-and-watch.md). **Partial coverage by design**: the real enforcement for both notification approval and Watch Mode's trigger authorization and injection safety runs as the two committed GitHub Actions workflows, `skills/squad/github-approval-watcher.workflow.yml` and `skills/squad/squad-watch.workflow.yml` — a consumer who never copies those into `.github/workflows/` has no enforcement here beyond these two logs.

Every other procedural or reference-only rule from the source instruction files (discovery/intake/council gate procedures, the roster and pack catalog, the federation layout, the Scribe write contract) is not hook-shaped — it lives in the reference files listed in the table above, read on demand rather than mechanically enforced.
