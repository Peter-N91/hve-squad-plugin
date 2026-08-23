---
name: squad-doctor
description: "Checks which hve-core-owned cast roles (security, RAI, privacy, accessibility, project-planning, design-thinking, coding-standards) are absent when only the hve-core Copilot plugin is installed, without an `apm install`. Use at squad Init, on request ('run squad-doctor', 'check for missing roles', 'what's not installed'), or any time a dispatch fails because a mapped Primary agent cannot be found."
license: MIT
metadata:
  authors: "Peter-N91/hve-squad"
---

# Squad Doctor

## Why This Exists

Per `hve-squad`'s own architecture decision (the plugin deliberately does not
vendor hve-core's domain content), the `hve-squad` plugin does **not** vendor
hve-core's domain content. When a consumer installs only this plugin (no
`apm install github/hve-core`), the `hve-core` Copilot plugin they may also
have installed ships **zero** files from seven domains: **accessibility,
security, privacy, RAI, project-planning, design-thinking, and
coding-standards**. Most of `squad-roster.instructions.md`'s cast catalog
casts against agents in exactly those seven domains — so most roster rows
resolve to an absent agent at dispatch time, and the roster's own rule is to
**escalate rather than dispatch a partial squad**. This check makes that gap
visible before a turn hits it, instead of failing mid-dispatch with an
unexplained "agent not found."

This check never vendors or duplicates hve-core's content (that would repeat
the rejected alternative) — it only reports what is present versus what the
roster expects.

## Inputs

None required. Optionally accepts **scope** (`all` default, or a single domain name) to narrow the report to one domain.

## Flow

1. **Enumerate dispatchable agents actually available in this session** — the set the coordinator could hand to `runSubagent`/`task` right now, by whatever discovery mechanism the host exposes (installed plugin agent listings, `apm install`-deployed `.github/agents/**`, or both).
2. **Check each of the seven domains below against its representative Primary agent name(s).** A domain is reported **present** only when at least one of its named Primaries actually resolves; **absent** otherwise. Do not guess from a partial match — an agent whose name merely sounds similar does not count.

   | Domain | Representative Primary agent name(s) to check for |
   |---|---|
   | `security` | `Security Planner`, `SSSC Planner`, `Skill Assessor`, `Supply Chain Skill Assessor`, `Finding Deep Verifier`, `Report Generator`, `CVE Analyzer` |
   | `rai` | `RAI Planner`, `RAI Skill Assessor` |
   | `privacy` | `Privacy Planner` |
   | `accessibility` | `Accessibility Framework Assessor`, `Accessibility Surface Inventory` |
   | `project-planning` | `PRD Builder`, `BRD Builder`, `Functional Planner`, `System Architecture Reviewer`, `ADR Creator`, `Meeting Analyst`, `UX UI Designer` |
   | `design-thinking` | `DT Coach`, `DT Learning Tutor` |
   | `coding-standards` | `Code Review Functional`, `Code Review Standards`, `Code Review Security`, `Code Review Accessibility` |

3. **Report per-domain, not just an aggregate.** For each domain: `present` (name the resolved agent) or `absent`. Never report a domain `present` on the strength of the squad's own `squad-*` glue agents (`Squad Reviewer`, `Squad Lead`, etc.) — those dispatch *to* the domain's agents and are not a substitute for them being present.
4. **Name the fix for every absent domain**, without vendoring the content itself: `apm install github/microsoft/hve-core` (full package) resolves all seven at once; a narrower ask is out of this check's scope — see the README's *Known Gap* section for the standing recommendation.
5. **Cross-check the mapping's currency.** This table mirrors `squad-src/.github/instructions/squad/squad-roster.instructions.md`'s cast catalog as of this plugin's build. If the roster changes which Primary a role resolves to, this table drifts — note that possibility in the report rather than presenting the table as infallible.

## Output

A short per-domain table (`present`/`absent` + resolved agent name or the fix) plus a one-line summary count (`N of 7 domains present`). Never silently drop a domain from the report.

## Invocation

This is a mechanical inspection, not a role dispatch — perform it directly rather than routing to a specialist agent. It complements, and does not replace, `hooks/scripts/session-start-check.sh` (which only checks squad-state file resolution, not cast availability).
