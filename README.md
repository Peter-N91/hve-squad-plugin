# hve-squad-plugin

This repository is a **generated, release-gated mirror** of
[`Peter-N91/hve-squad`](https://github.com/Peter-N91/hve-squad)'s `squad-src/`
GitHub Copilot CLI plugin distribution tree.

It is **never hand-edited**. Its content (`agents/`, `skills/`, and
`.github/plugin/plugin.json`) is regenerated only when `hve-squad` cuts a
release, extracted from that release's immutable git tag — never from a live
working tree or a moving branch. See
`Peter-N91/hve-squad`'s
[ADR-0001](https://github.com/Peter-N91/hve-squad/blob/main/docs/architecture/adr/0001-plugin-distribution-repo-topology.md)
(build-provenance amendment: tag-pinned builds only) and
[ADR-0006](https://github.com/Peter-N91/hve-squad/blob/main/docs/architecture/adr/0006-plugin-distribution-moves-to-separate-repo.md)
(this repository's existence: the generated plugin distribution tree lives
here, outside `hve-squad`'s own working tree, mirroring the existing
`hve-squad-mcp` sibling-repo pattern) for the full rationale.

## Current source provenance

- Built from `Peter-N91/hve-squad` tag `v0.16.0-pre`
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
