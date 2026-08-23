# hve-squad-plugin

This repository is a **generated, release-gated mirror** of
[`Peter-N91/hve-squad`](https://github.com/Peter-N91/hve-squad)'s `squad-src/`
GitHub Copilot CLI plugin distribution tree.

It is **never hand-edited**. Its content (`agents/`, `skills/`, and
`.github/plugin/plugin.json`) is regenerated only when `hve-squad` cuts a
release, extracted from that release's immutable git tag — never from a live
working tree or a moving branch.

This repository exists so the generated plugin distribution tree lives
outside `hve-squad`'s own working tree, mirroring the existing
`hve-squad-mcp` sibling-repo pattern. `hve-squad`'s own architecture decision
records (the build-provenance rule behind this repo, and the decision to
split it out as a separate repository) are internal design records and are
not published alongside this repo's own history.

## Current source provenance

- Built from `Peter-N91/hve-squad` tag `v0.16.0`
- Extraction date: 2026-08-23

## Structure

- `agents/squad/` — the plugin's Squad Copilot agents
- `skills/squad/` — the plugin's Squad skill and its bundled references
- `.github/plugin/plugin.json` — the plugin manifest (Open Plugin Spec)

## Do not hand-edit

`agents/`, `skills/`, and `.github/plugin/` are generated output. Do not edit
files under these paths by hand — changes will be silently overwritten the
next time this repository is regenerated from a `hve-squad` release tag. See
`CODEOWNERS` for the enforcement convention.

## Known gap: hve-core plugin does not cover seven domains

Installing only this plugin (no `apm install`) is the "zero-install, works
everywhere" path this plugin exists for. It has one real limitation:
the `hve-core` Copilot plugin — even when a consumer also installs it — ships
**zero files** from seven domains that most of the squad's cast catalog
(`squad-roster.instructions.md`) casts against: **accessibility, security,
privacy, RAI, project-planning, design-thinking, and coding-standards**.
Representative absent Primaries include `Security Planner`, `RAI Planner`,
`Privacy Planner`, `PRD Builder`, `System Architecture Reviewer`, `DT Coach`,
and `Code Review Functional`.

This is a deliberate trade-off, not an oversight: this plugin does **not**
vendor hve-core's domain content (that would duplicate and drift from the
upstream source of truth). Instead:

* **Run `squad-doctor`** (`skills/squad/invocations/squad-doctor/SKILL.md`) at
  Init or any time a dispatch fails with an unresolved agent. It reports,
  domain by domain, which of the seven are present versus absent in the
  current session, rather than letting a roster row fail silently mid-turn.
* **The fix, when a domain reports absent**, is `apm install
  github/microsoft/hve-core` (the full APM package) in the consuming
  repository, which resolves all seven at once. This plugin has no narrower
  per-domain install path to offer today; that is an upstream ask tracked
  separately (see the `hve-squad` repository's Phase 4 distribution plan).

A consumer who never runs `apm install` and never checks `squad-doctor`'s
report may see most roster rows resolve to an absent agent and get escalated
rather than silently dispatched to the wrong thing — that escalation is the
squad's own roster rule (`squad-roster.instructions.md`, *Dispatchability*)
working as intended, not a defect in this plugin.

