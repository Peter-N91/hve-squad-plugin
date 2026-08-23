---
name: squad-run
description: "Routes a request to the Squad Coordinator, which dispatches a cast of HVE Core agents in parallel and persists squad state. Use when the user asks to run, initialize, or continue a squad, or names a squad profile, pack, discovery depth, model tier, owner, or autonomy mode (autonomous/autopilot)."
license: MIT
metadata:
  authors: "Peter-N91/hve-squad"
---

# Squad Run

## Inputs

* **request** (required): The work for the squad this turn, from the user's own words.
* **profile** (optional): The squad profile to seed when the project has no squad yet (`default`, `full`, `security`, `design`, `accessibility`, `architecture`, `azure`, `modernization`, `compliance`, `operations`, or `product`). Selects which cast the coordinator stamps out during Init Mode.
* **pack** (optional): One or more comma-separated packs added on top of the profile (`power-platform`, `m365-copilot`, `aws`). A pack carries a technology vertical's specialist roles and never replaces the profile.
* **discovery** (optional): The depth of the opt-in discovery gate for this turn (`quick`, `standard`, `deep`, or `skip`). When omitted, the coordinator offers it once per topic in a `product` or `full` squad and stays silent in every other profile. Ignored on an unattended run.
* **tier** (optional): A model-tier hint (`fast` or `default`) overriding cost-first defaults for this turn.
* **owner** (optional): A `Member Name` from `team.md` that picks a specific named member when two rows share the same role.
* **mode** (optional): The autonomy mode for this turn — `autonomous` or `autopilot`. When omitted, the coordinator uses the standard interactive tiers, approving each step.

## Flow

1. Hand **request** (and **owner** when provided) to the Squad Coordinator agent and let its per-turn protocol classify, dispatch, and synthesize the response.
2. Pass **profile** through as the Init Mode profile hint when provided, and **pack** through as the Init Mode pack hint when provided. When the project has no squad and no profile is given, let the coordinator discover the project and propose a recommended profile before seeding.
3. Pass **tier** through as the per-turn tier override when provided; otherwise leave model selection to the coordinator.
4. Pass **discovery** through as the discovery-gate depth when provided; otherwise let the coordinator decide whether to offer the gate.
5. When **mode** is `autonomous`, request the `auto-validated` tier (bounded re-validation loop, always-escalate triggers); when **mode** is `autopilot`, request the full research→plan→implement→review pipeline (Human Gates on impactful actions and final-outcome validation only); otherwise rely on the standard interactive tiers.
6. Let the coordinator own roster, routing, state, and the notification contract — it seeds `.copilot-tracking/squad/{team.md,routing.md,state.json}` on first run and persists decisions, history, and notifications through the Squad Scribe.

## Invocation

Dispatch this request to the `Squad Coordinator` agent. This skill does not run the coordination logic itself — it only resolves which parameters to pass.