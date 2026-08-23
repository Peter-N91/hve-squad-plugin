---
name: squad-floor
description: "The unconditional squad floor: state paths, single-writer Scribe rule, dispatch discipline, proof of dispatch, the literal consumption block, and the Research to Plan to Implement to Review spine."
license: MIT
metadata:
  authors: "Peter-N91/hve-squad"
  spec_version: "1.0"
  last_updated: "2026-08-23"
---

# Squad Floor

This file carries the squad rules that must hold before any file is in play — ported from `squad-src/.github/instructions/squad/squad-floor.instructions.md`, which was `applyTo: '**'` (global) in the APM package because a freshly dispatched agent that has not yet touched squad state runs without every other squad file. In the plugin distribution there is no `applyTo` mechanism, so this reference file is the floor's model-readable home; `hooks.json`'s `sessionStart` and `preToolUse` entries are its mechanically enforced half (see `hooks/README.md`).

## When This Applies

These rules bind any turn that runs, resumes, or writes to a squad. Ordinary work in a project is unaffected.

## Squad State Paths

All squad state lives under a **squad root**: `.copilot-tracking/squad/` for a single squad, or `.copilot-tracking/squad/members/<name>/` for a sub-squad in a federation.

| Path                   | Purpose                                     | Write semantics    |
|------------------------|---------------------------------------------|--------------------|
| `team.md`              | Roster of roles and the agents filling them | Replace via Scribe |
| `routing.md`           | Request-pattern routing table               | Replace via Scribe |
| `decisions.md`         | Squad decisions and their rationale         | Append-only        |
| `notifications.md`     | Notifications fired and their channel       | Append-only        |
| `history/<agent>.md`   | Per-agent dispatch history                  | Append-only        |
| `state.json`           | Machine-readable squad status               | Replace via Scribe |
| `consumption.md`       | Member, model, and credit ledger            | Replace via Scribe |
| `consumption-rates.md` | Per-model token-rate table                   | Replace via Scribe |

`<agent>` is the agent's `name:` frontmatter value **verbatim** — spaces and capitalization intact, as in `history/BRD Builder.md`. Never slugify, lowercase, or substitute the role id; a renamed file reads as a missing entry and drops that agent from every later ledger rewrite.

Init seeds `history/` **empty**. Each file inside it is created by the dispatch it records, so its presence is what proves that stage ran; a header-only file seeded per roster member at Init destroys that signal.

Detection precedence: `federation.md` present means federation; otherwise `team.md` present means a single squad; otherwise the squad is not initialized and Init Mode runs. Squad state is runtime-created and is never packaged with the squad source.

## The Squad Scribe Is the Single Writer

Only the **Squad Scribe** writes squad state. Every other agent, including both coordinators, reads state to decide and hands each mutation to the Scribe through `runSubagent` or `task`. This is what lets parallel dispatch run without racing on the same files.

Append-only files are appended to and never edited or removed. A coordinator that edits `decisions.md`, `history/`, or `state.json` directly has broken the contract, even when the edit is correct.

**Line numbers are never file content.** A read tool renders a `1.`, `2.`, `12:` gutter down the left margin so you can cite a line; it belongs to the viewer, not to the file. Copying a template out of a numbered view and writing it back with the gutter intact produces a file nothing downstream can parse. Strip the numbering before writing, every time.

**Hook backstop (partial):** `hooks.json`'s `state-write-guard` denies a full-overwrite (`create`) of an append-only file that already has content. It cannot verify the caller is the Scribe — `preToolUse` payloads carry no caller identity — so the single-writer half of this rule remains a model-followed convention. See `hooks/README.md`.

## Dispatch Discipline

A coordinator classifies, dispatches, collects, synthesizes, and escalates. It never performs a role's work itself, in any mode — interactive, autonomous, or autopilot. This is the rule that makes the squad a methodology rather than one model improvising.

* Producing research, a plan, a Council Verdict, implementation, or a review inline instead of dispatching the mapped agent is a protocol violation, even when inlining would be faster.
* **Loading or invoking a specialist skill is role work.** Classify only from the request and the roster and routing metadata, and activate only the `squad` skill itself. Host discovery metadata may establish that a skill exists; only the resolved specialist activates it, and only after dispatch.
* Every stage runs by dispatching its mapped agent against the `user-invocable: false` agent the roster resolves.
* When a mapped agent is missing or not dispatchable, **stop and escalate**. Never substitute your own reasoning and never swap in an unmapped agent.
* Running on a fast or auto-selected model never relaxes any of the above. Determinism completes a squad turn, not model strength.

## Resolving a Role to an Agent

A roster row names one **Primary** agent and optionally some **Alternates**. The Primary is what the role dispatches; an Alternate is a documented exception, never a preference.

* **Dispatch the Primary unless a Selection Cue you actually read matches the request.** The cue lives in the roster row's `Selection Cue` cell, seeded at Init from the cast catalog. Reading the `Alternate Agents` cell tells you an alternate exists, not when to use it.
* **No cue in hand means the Primary.** A roster with no `Selection Cue` column, a cue that does not match, or a cue table you could not load all resolve the same way: dispatch the Primary. Picking the alternate that sounds closest to the request is a guess, and it silently swaps the methodology the role was cast for.
* **Record any non-primary resolution** through the Scribe, naming the cue that selected it, so the history entry explains why that agent ran.

## Proof of Dispatch

A stage counts as run only when both exist: its domain artifact on disk at the role's `Deliverable Root`, and a `history/<agent>.md` entry written by the Scribe carrying the dispatch's consumption block. No history entry means the stage did not happen and the turn cannot advance past it.

A history file is created by the dispatch it records, with this preamble and nothing else above the first entry:

```markdown
---
description: "Append-only dispatch history for a single squad agent"
---

# History: <agent>
```

The heading is literally `# History: <agent>` — not the bare agent name, not a rewrite of the description. A later turn locates the file by that heading, so a file headed `# Squad Researcher` reads as a file with no heading at all and drops that agent from every ledger rewrite. The file name is the agent's `name:` verbatim, so `history/Squad Scribe.md`, never `history/scribe.md`.

Verification is an act, not an assertion: list the directory and read the file. Never report a path this turn did not actually enumerate.

**A stage recorded as complete in `state.json` but absent from `history/` did not run.** The history file is the evidence; a status field is a claim about it. Autonomous and autopilot runs remove the human turn between stages, not this check — when the file is missing, stop at that stage and escalate rather than advancing on the strength of the claim.

**Every dispatch is handed over, one payload per dispatch, as it returns.** The Scribe writes what it is given and cannot record a dispatch nobody mentioned. Assembling the run's history at the end from memory reliably drops the stages that ran earliest.

### The Deliverable Root Is Binding

The `Deliverable Root` cell of the role's `team.md` row is where that role's artifact goes. It is an operator declaration, not a default, and it **overrides any path convention carried in the dispatched agent's own definition**.

* **Write there, or stop and escalate.** A role that cannot use the root it was given says so; it never substitutes a path it prefers.
* **A `<date>` or `<slug>` segment is a directory, not a filename prefix.** `.copilot-tracking/research/<date>/` means `.copilot-tracking/research/2026-08-21/topic.md`, never `.copilot-tracking/research/2026-08-21-topic.md`. **Substitute it; never write the angle brackets.**
* **The entry's `Deliverable:` path is the artifact's real path** — resolved, confirmed to exist by listing it, and under that role's root.
* **Write the path the way the root is written.** The `Deliverable:` path extends the `Deliverable Root` cell verbatim.
* **A stage that wrote no file did not run.** `Deliverable: N/A`, `inline verdict`, `no artifact written`, and an entry with no `Deliverable:` line at all are the same statement: this stage produced nothing the next one can read.

A promotion rebases the roster's roots but **cannot rebase the entries**. History is append-only, so a `Deliverable:` path recorded before a promotion still names the pre-promotion location while the file now sits under `members/<name>/`. Resolve it through the relocation the promotion recorded; never edit the entry to match.

Reconcile both directions before reporting a run complete: every `Deliverable:` path names a file that exists, and every file under a role's Deliverable Root is claimed by some history entry. **An unclaimed artifact is a dispatch nobody recorded** — stop and escalate rather than reporting the run complete.

## The Consumption Block Is Literal

Every dispatch entry carries a `#### Consumption` heading followed by a fenced `json` block — level four, no suffix. The only legal variant is `#### Consumption — Orchestration`, which the coordinator's and Scribe's own turns are recorded under in `history/Squad Scribe.md`. Any other heading is unreadable to the ledger rewrite, so the dispatch it records is spent and uncounted.

**A block records what was consumed, never what it cost.** Rates and money live in `consumption.md` and `consumption-rates.md` and appear nowhere else.

The field names, their `snake_case` spelling, their order, and the set itself are contractual. Copy this shape; do not translate it into camelCase, and do not add fields of your own:

```json
{
  "model": "<resolved model or unknown>",
  "model_source": "<dispatch-reported|agent-pinned|operator-declared|session-inherited|cli-pinned|unresolved>",
  "priced_as": "<rate row this dispatch prices from>",
  "model_tier": "<fast|default|extended>",
  "internal_turns": 0,
  "input_tokens": 0,
  "cached_tokens": 0,
  "cache_write_tokens": 0,
  "output_tokens": 0,
  "basis": "<estimated|tier-default>"
}
```

Every numeric field is a bare number: `172800`, never `~172,800`, `"172800"`, or `172800 tokens`.

* **The set is closed at ten.** Estimator working values, `input_rate`/`cached_rate`/`cache_write_rate`/`output_rate`, and `est_cost_usd`/`est_credits` all belong to the ledger, never this block.
* **`priced_as` is always present, and it is copied character-for-character from the rate table's `Model (as routed)` cell.** `Claude Sonnet 5`, never `claude-sonnet-5`.
* **`model_tier` is the `Tier` cell of that same row.** Not the roster's `Model Tier` for the role, and not a judgment about how heavy the dispatch felt.

**Size each dispatch from that dispatch.** Two blocks carrying identical token counts describe one dispatch recorded twice, not two dispatches that happened to consume the same amount.

## Two Files the Ledger Reads Back

`consumption-rates.md` is **copied verbatim** from the template in the `squad` skill's `references/consumption.md`, at Init and at every sub-squad seeding or federation promotion. It carries the per-model rate table, the tier-fallback table, the dispatch-size estimator, and the calibration block, and all four are load-bearing.

In `consumption.md`, the row covering the coordinator's and Scribe's own turns is labelled **`orchestration`** in both tables — never `scribe`, `coordinator`, or a split pair. No block means no row.

An orchestration entry takes the same prose shape a dispatch entry takes:

```markdown
### <timestamp> <what this turn wrote>

* Turn: <n>
* Request: <what the coordinator handed over>
* Deliverable: <the state files this turn wrote>
* Outcome: <one line>

#### Consumption — Orchestration
```

The ten-field block follows that heading, fenced as `json`, exactly as a dispatch entry's does.

**This file is the only place cost is derived.** For each row, sum that role's blocks into the `Turns` column and the four token columns — five columns, not four — then look up the rates once from the row `priced_as` names in `consumption-rates.md`. Compute the four products separately, sum them, divide by `1e6`, then multiply by the `calibration_factor`:

```text
 57600 ×  3.00  =  172800
230400 ×  0.30  =   69120
 95200 ×  3.75  =  357000
 15000 × 15.00  =  225000
                  -------
                   823920  / 1e6  =  0.82392 USD  ->  82.39 credits
```

Credits are `est_cost_usd / 0.01`. **Show the arithmetic in the file** under a `### Derivation` block, one line per row. **The total row is computed, never carried** — sum every column down the rows the rewrite just wrote. **The Cost Comparison section is required**, naming what this run cost, what the manual baseline would have cost, and the saving as a percentage.

Full worked derivation, ledger-row rules, and the run-total/comparison mechanics live alongside the Scribe's own write contract in [scribe-procedure.md](scribe-procedure.md) — this file states the literal, load-bearing block shape; that one states the procedure around it.

## The Methodology Spine Is Not Optional

Every squad turn that produces substantive output runs **Research → Plan → Implement → Review**, in every mode and on every profile. The spine roles (`researcher`, `lead`, `developer`, `tester`) are seeded into every roster for this reason.

* The output being a document rather than code changes nothing. A BRD, roadmap, journey map, experiment plan, or deck is produced *by* the methodology, not instead of it.
* Before dispatching the role that produces the output, confirm a research artifact and a plan artifact exist on disk for the topic. When either is missing, dispatch the owning role first — never author it inline and never advance without it.
* After the output lands, dispatch `tester` as the closing stage before reporting the work complete.

A run whose first dispatch is the deliverable's owner skipped the methodology. The gate procedure lives in *Implementation Gate Procedure* in [gates-and-modes.md](gates-and-modes.md).

## Model Frontmatter Is a String

`model:` is a single string on every host. A YAML array is accepted by VS Code and makes the agent fail to load on the Copilot CLI. Per-role preference belongs in the `Model Tier` column of `team.md`, not in an array.

## Where the Procedure Lives

* [00-index.md](00-index.md) — start here; routes to every other reference file and to the `hooks.json` entries that mechanically back the rules above.
* `hooks.json` at the plugin root — the enforced half of this file's single-writer, append-only, and Impactful-Action rules. See `hooks/README.md` for exactly what each hook checks and does not check.

Apply what you read verbatim. Do not invent a role, agent, profile, pack, or state file the skill and roster do not define.
