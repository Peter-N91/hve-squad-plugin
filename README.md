# hve-squad-plugin

This repository is a **generated, release-gated mirror** of
[`Peter-N91/hve-squad`](https://github.com/Peter-N91/hve-squad)'s `squad-src/`
GitHub Copilot CLI plugin distribution tree.

## Documentation

Full documentation lives on the project site:

**[peter-n91.github.io/hve-squad-plugin](https://peter-n91.github.io/hve-squad-plugin/)**

| Page                                                                                    | What it covers                                                    |
|------------------------------------------------------------------------------------------|---------------------------------------------------------------------|
| [Install: Copilot CLI](https://peter-n91.github.io/hve-squad-plugin/install-cli.html)     | Registering the marketplace, installing both plugins, and updating them as a pair |
| [Install: Desktop app](https://peter-n91.github.io/hve-squad-plugin/install-desktop.html) | The GitHub Copilot desktop app / VS Code Plugins settings path       |
| [Install: VS Code notes](https://peter-n91.github.io/hve-squad-plugin/install-vscode.html) | VS Code specifics and the non-plugin, MCP-only alternative           |
| [Architecture](https://peter-n91.github.io/hve-squad-plugin/architecture.html)            | Plugin vs. MCP server invocation surfaces, and the version-pinning gap |
| [Enterprise Push](https://peter-n91.github.io/hve-squad-plugin/enterprise-push.html)      | Force-installing this plugin org-wide via Copilot enterprise settings |

The site source is in [docs/](docs/) and is published to GitHub Pages by
[.github/workflows/docs.yml](.github/workflows/docs.yml) on every push to `main` that touches
`docs/`.

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

- Built from `Peter-N91/hve-squad` tag `v0.16.2`
- Extraction date: 2026-08-25

## Structure

- `agents/squad/` — the plugin's Squad Copilot agents
- `skills/squad/` — the plugin's Squad skill and its bundled references
- `.github/plugin/plugin.json` — the plugin manifest (Open Plugin Spec)

## Do not hand-edit

`agents/`, `skills/`, and `.github/plugin/` are generated output. Do not edit
files under these paths by hand — changes will be silently overwritten the
next time this repository is regenerated from a `hve-squad` release tag. See
`CODEOWNERS` for the enforcement convention.

## Installing and updating

Both marketplace entries must be installed, always as a pair:

```bash
copilot plugin marketplace add Peter-N91/hve-squad-plugin
copilot plugin install hve-squad@hve-squad-plugin
copilot plugin install hve-squad-hve-core@hve-squad-plugin
```

Two rules govern every later update. Both are explained in full on
[Install: Copilot CLI](https://peter-n91.github.io/hve-squad-plugin/install-cli.html).

### `hve-squad-hve-core` must be uninstalled, then installed — never updated

```bash
copilot plugin marketplace update Peter-N91/hve-squad-plugin
copilot plugin update hve-squad@hve-squad-plugin

copilot plugin uninstall hve-squad-hve-core@hve-squad-plugin
copilot plugin install   hve-squad-hve-core@hve-squad-plugin
```

`copilot plugin update` compares the version recorded at install time against the
version it resolves now, and for this entry both come from **upstream hve-core's own
`plugin.json`** (e.g. `3.2.2`) rather than from this marketplace's `version` field.
When a release bumps only `source.sha` and upstream hve-core's version is unchanged,
the two match, the CLI answers `already at latest`, and the previously fetched tree
stays on disk. The pin moves; the files do not. Uninstalling clears that recorded
state so the reinstall resolves `source.sha` fresh.

Run the pair once per plugin home you dispatch from. Plugins live under
`$COPILOT_HOME`, and clients embedding the Copilot CLI often point it somewhere other
than `~/.copilot`, so updating in a terminal does not update an embedding client's copy.

### Do not also install the official `hve-core` plugin

If you run the squad, take hve-core **only** through this marketplace's
`hve-squad-hve-core` entry. Installing the official `hve-core` plugin from
`microsoft/hve-core` alongside it registers a second copy of every hve-core agent and
skill, tracking whatever is current upstream instead of the validated commit. Squad
roles resolve to hve-core agents by name, so a dispatch can land on that unpinned copy,
and the routing tables, role charters, and cast-delta guarantees your installed
hve-squad release was built against no longer hold.

The `hve-squad-hve-core` entry is named distinctly so both *can* be registered without
a name collision at install time. That is a packaging safeguard, not a recommendation
to run both. If the official plugin is already installed, remove it before dispatching
the squad, or keep it in a separate `$COPILOT_HOME`.

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

