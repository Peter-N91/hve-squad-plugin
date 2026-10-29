---
name: squad-init-hooks
description: "Writes the squad's hooks.json guards into the consuming repository's own .github/hooks/ so they also run under Copilot cloud agent, which only loads repository-level hook files and never a plugin's own hooks.json. Use when the user asks to enable squad hooks for the cloud agent, wants hooks to work on GitHub.com, or asks to run '/squad init' or 'squad-init-hooks'."
license: MIT
metadata:
  authors: "Peter-N91/hve-squad"
---

# Squad Init Hooks

## Why This Exists

Per the GitHub Copilot hooks reference, a plugin's own `hooks.json` is loaded by **Copilot CLI only**. **Copilot cloud agent loads hook configuration exclusively from `.github/hooks/*.json` files committed in the cloned repository** — it never reads a plugin's `hooks.json`. So this plugin's guards (the Impactful-Action Gate, the append-only/single-writer backstop, the dispatch-time gates, the autonomous escalation check) run for a CLI or desktop-app session, but not for a Watch Mode run or any other cloud-agent job, unless a copy is committed at the repository level.

This is a **single-purpose action**: it drops hook files into the consuming repository. It does nothing else — no roster seeding, no profile selection, no `team.md`/`routing.md` creation.

## Inputs

* **targetDir** (optional, defaults to `.github/hooks/`): where to write the hook configuration and its scripts in the consuming repository.
* **force** (optional, defaults to `false`): when `true`, overwrite an existing `hve-squad.json`/`hve-squad/` drop from a prior run of this same skill. Never overwrites a file this skill did not itself create — see *Idempotency* below.

## Flow

1. **Read the plugin's own `hooks.json`** and its referenced scripts under `hooks/scripts/`.
2. **Filter to the cloud-agent-relevant subset.** Copilot cloud agent honors the plugin's events but only the `bash` command field (`command` is a fallback); it ignores the `powershell` field. Keep each Bash entry. The dispatch guard's Bash wrapper calls `pwsh`, so its PowerShell implementation and runtime dependencies must also travel with the drop. PowerShell 7.4+ must be available in the cloud setup, as it is for the squad runtime; disclose this prerequisite rather than installing it or claiming the hook was executed.
3. **Write the hook configuration** to `<targetDir>/hve-squad.json`, with paths rewritten relative to the repository root (cloud agent's working directory is `/workspace` when a repository is cloned) rather than the plugin's own install directory.
4. **Copy the Bash scripts** to `<targetDir>/hve-squad/*.sh`, preserving execute permissions. Also copy `dispatch-guards.ps1` beside its wrapper and the skill's `scripts/SquadCoordinator.psm1`, `scripts/Resolve-SquadConnectorDispatch.ps1` and `scripts/SquadAgentDiscovery.ps1` into `<targetDir>/hve-squad/runtime/`. These are the dispatch guard's required dependencies; the other PowerShell companions are not used by cloud agent.
5. **Report exactly what was written** — the hook file path, each script path, and a one-line note that this drop must be committed to take effect for cloud agent (an uncommitted local file is invisible to a cloud-agent job, which operates on the cloned repository, not the developer's working tree).

## Idempotency

* A top-level `"_generatedBy": "squad-init-hooks"` field is written into `hve-squad.json` so a re-run can recognize its own prior output.
* Re-running without `force` when the marker is present and unchanged is a no-op that reports "already up to date."
* Re-running when the target file exists **without** the marker (a human-authored `.github/hooks/hve-squad.json`, or a differently-named file that happens to collide) refuses to overwrite it and reports the conflict, asking the user to rename one side — the same no-clobber discipline the federation naming rule uses elsewhere in the squad.

## What This Skill Does Not Do

* It does not run `apm install` or seed any roster/profile state.
* It does not enable Watch Mode itself — the two GitHub Actions workflows (`skills/squad/github-approval-watcher.workflow.yml`, `skills/squad/squad-watch.workflow.yml`) are a separate, explicit copy-and-commit step a consumer performs when they want Watch Mode's actual trigger and approval enforcement, not just its hooks-layer backstop.
* It does not touch `.mcp.json` or any MCP server registration.

## Invocation

Perform this as a direct file-write action — it is a mechanical copy-and-rewrite, not a role dispatch.