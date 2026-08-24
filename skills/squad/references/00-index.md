---
name: squad-reference-index
description: "Which squad reference file to read for which job, plus the companion instruction files that auto-apply when squad state is touched."
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
| [profiles-and-packs.md](profiles-and-packs.md)     | Seeding or amending a roster: profile choice, packs, which roles exist    |
| [operating-procedure.md](operating-procedure.md)   | Running a turn: Init, Route, ledger reconciliation, Decide, Handoff       |
| [gates-and-modes.md](gates-and-modes.md)           | Gates ÔÇö discovery, intake, council, implementation ÔÇö and autonomy modes   |
| [federation.md](federation.md)                     | The squad root is a federation: layout, precedence, federation modes      |
| [scribe-procedure.md](scribe-procedure.md)         | Writing squad state, Scribe only: every payload-to-step rule and contract |
| [entry-schemas.md](entry-schemas.md)               | Any ordinary write turn: decision and verdict entries, history, state.json |
| [seed-templates.md](seed-templates.md)             | Stamping first-run state, Init only: `team.md` and `routing.md`           |
| [consumption.md](consumption.md)                   | Recording or estimating cost: ledger templates and the estimator          |
| [federation-templates.md](federation-templates.md) | Creating or expanding a federation: registry, meta-routing, root files    |

The Scribe reads `00-index.md`, `scribe-procedure.md`, and `entry-schemas.md` on every turn, and reads `consumption.md`, `seed-templates.md`, and `federation-templates.md` only when the turn's payload writes their files. The coordinators read `seed-templates.md` and `federation-templates.md` only to verify deliverable roots during Init or a federation change.

## Companion hook rules and reference files

In the plugin distribution these rules do not ship as `.instructions.md` files, because the plugin surface has no instructions channel to apply them. Deterministic enforcement moves to `hooks.json`; the full rule text of every file below is ported verbatim under `references/rules/`, and the citations in this section resolve there. The distilled reference files above remain the curated entry points — read those first, and read `references/rules/` when you need the complete rule.

* `skills/squad/references/rules/squad-roster.md` ÔÇö roster schema and cast catalog.
* `skills/squad/references/rules/squad-routing.md` ÔÇö routing table and escalation rules.
* `skills/squad/references/rules/squad-discovery-gate.md` ÔÇö opt-in pre-work discovery gate, scoped to the `product` and `full` profiles, that brainstorms a brief when a turn has no requirement or input artifact to build on, with depth tiers, an offer-once rule, an unattended-run prohibition, and the Discovery Verdict schema.
* `skills/squad/references/rules/squad-intake-gate.md` ÔÇö conditional pre-work intake gate that validates requirement and input artifacts before planning or implementation, with a bounded auto-remediation loop and the Intake Readiness Verdict schema.
* `skills/squad/references/rules/squad-state.md` ÔÇö state layout, single-writer ownership, and tool-to-mechanism mapping.
* `skills/squad/references/rules/squad-council.md` ÔÇö pre-implementation council protocol with parallel dispatch, most-restrictive-wins synthesis, and the Council Verdict schema.
* `skills/squad/references/rules/squad-autonomous.md` ÔÇö opt-in `auto-validated` autonomy tier with a bounded re-validation loop, divergence detection, and mandatory escalation triggers.
* `skills/squad/references/rules/squad-autopilot.md` ÔÇö opt-in `mode=autopilot` full pipeline (researchÔåÆplanÔåÆimplementÔåÆreview) with Human Gates only on impactful actions and final-outcome validation.
* `skills/squad/references/rules/squad-notifications.md` ÔÇö user-contact capture at squad build time and the delivery-agnostic notification (ping) contract per mode.
* `skills/squad/references/rules/squad-watch-mode.md` ÔÇö event-driven Watch Mode (DR-01) trigger contract: opt-in gates, event-to-intent map, injection-safe payloads, the event-scoped sub-squad bootstrap, and the pull-request deliverable.
* `skills/squad/references/rules/squad-federation.md` ÔÇö opt-in federation of named sub-squads under one repo: the parameterized squad root, the registry (`federation.md`) and meta-routing (`meta-routing.md`) schemas, detection precedence, and the two-level single-writer rule.
* `skills/squad/references/rules/squad-federation-autopilot.md` ÔÇö opt-in federation-level autopilot: the meta-pipeline (`mode=autopilot` with no `squad=` target) that orders sub-squad autopilot runs under one set of federation gates, an aggregate cost ceiling, and one consolidated final-outcome validation.