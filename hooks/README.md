# Squad Plugin Hooks

This directory documents the plugin-contributed `hooks.json` at the repository
root and the scripts it invokes. It is the P03-T01 deliverable: a
best-effort, deterministic backstop for the enforcement conventions that
`squad-src/.github/instructions/squad/*.instructions.md` describe as prose.

**Read this file before trusting any hook as a full mechanical guarantee.**
The real GitHub Copilot hook contract (confirmed against the published
[hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference),
not the conversion plan's simplified "event + condition" framing) is narrower
than a declarative policy engine: a hook is a shell script invoked with a
JSON payload on stdin, and it signals its decision through stdout JSON plus
its exit code. Several of the source instruction files' conditions do not
survive that translation intact, and this file records exactly which ones.

## What each hook actually enforces

| Hook file | Event | Source instruction file(s) | What is actually checked | Known limitation |
|---|---|---|---|---|
| `impactful-action-gate.sh`/`.ps1` | `preToolUse` (matcher `bash\|powershell`) | `squad-autopilot.instructions.md` (Impactful-Action Gate), `squad-watch-mode.instructions.md` (absolute variant) | Greps the raw shell command text for `git push`, `terraform apply`, `az ... create\|delete`, `gh pr merge`, `kubectl apply\|delete`, `npm publish`, secret-rotation-shaped commands, and destructive filesystem ops. Returns `permissionDecision: "ask"` with a reason naming the gate, so the human approves in-session and the action then proceeds — the stop → approve → proceed sequence the source file describes. | Pattern-matching a command string cannot cover every impactful action (for example, a Python script that calls the Azure SDK directly rather than shelling out to `az`). This is a backstop layer, not a complete classifier. The "Watch Mode is absolute, interactive can be overridden" distinction **is** expressible here and is what `ask` buys: per the hooks reference, `ask` prompts the human under interactive Copilot CLI, and is converted to `deny` automatically under cloud agent and other non-interactive surfaces, where no user is available to answer. |
| `state-write-guard.sh`/`.ps1` | `preToolUse` (matcher `create\|edit`) | `squad-floor.instructions.md`, `squad-state.instructions.md` (single-writer, append-only) | Denies a `create` (full-overwrite) tool call whose target path matches an append-only squad-state file (`decisions.md`, `notifications.md`, `federation.md`, `history/*.md`) **when that file already exists on disk** — a full overwrite of an existing append-only log is exactly the violation the source files describe. | **Cannot enforce the "only the Squad Scribe writes" half of the rule.** The `preToolUse` payload (confirmed from the hooks reference) carries `sessionId`/`cwd`/`toolName`/`toolArgs` — it does not carry the name of the calling (sub)agent. Caller identity is not observable at this hook, so that half of the single-writer rule remains a model-followed convention, not a hook-enforced one. This hook also cannot distinguish a legitimate append (`edit` appending to file end) from a modification of prior bytes, because it receives the proposed tool arguments, not a computed diff; `edit`-tool calls against these paths are allowed through unchecked by this hook (audited only, via `notification-audit.sh`'s general command logging is unrelated — no dedicated audit exists for `edit` calls in this pass). |
| `dispatch-guards.sh`/`.ps1` | `preToolUse` (matcher `task`) | `squad-intake-gate.instructions.md`, `squad-routing.instructions.md` (Tracker-Write Gate), `squad-federation.instructions.md` (naming + no-overwrite) | Three independent, best-effort checks against a `task` (subagent dispatch) call: (1) if `.copilot-tracking/squad/decisions.md` (or a federation member's copy, checked at the default single-squad path only) ends with an Intake Readiness Verdict block containing `Not-Ready`, denies a dispatch whose text looks like a plan/implement stage; (2) if the dispatch text looks tracker-write-shaped (mentions creating/pushing work items to ADO/Jira) and does not name `Squad Backlog Executor`, denies; (3) if the dispatch text names a `members/<name>/` path whose `<name>` fails `^[a-z0-9][a-z0-9-]*$`, denies. | Text-pattern matching on the dispatch prompt, not a parse of the actual roster/decision state beyond one grep. A federation sub-squad's `decisions.md` is not resolved automatically (only the default single-squad path is checked) — a multi-sub-squad federation gets no intake-gate backstop from this hook today. The no-overwrite half of the federation guard (does `members/<name>/` already exist) is not checked here because the hook does not know which repository root the dispatch will resolve `squadRoot` against with confidence beyond `cwd`. |
| `session-start-check.sh`/`.ps1` | `sessionStart` | `squad-floor.instructions.md` (state paths must resolve before dispatch) | Informational only: checks whether `.copilot-tracking/squad/team.md` or `federation.md` exists relative to `cwd`, and whether `state.json` parses as JSON when present. Cannot block — `sessionStart` only supports `additionalContext` injection. | No enforcement power; a malformed `state.json` is surfaced as context, not prevented. |
| `autonomous-escalation-check.sh`/`.ps1` | `subagentStop` | `squad-autonomous.instructions.md` (mandatory escalation triggers) | Scans the completed subagent's own response text (`response` / `last_assistant_message`, confirmed present on this event's payload) for `Verdict: Stop`, `Risk: High`, `compliance violation`, or `irreversible` language, and returns `decision: "block"` with a reason forcing the coordinator to escalate rather than continue silently. | This is the one condition from Section 4a's table that a `preToolUse` hook genuinely cannot see (a subagent's own findings are not tool arguments) — `subagentStop` is the correct event for it, which is a deliberate deviation from the conversion plan's `preToolUse` assumption, recorded here rather than silently substituted. Keyword matching against free text is inherently approximate. |
| `notification-audit.sh`/`.ps1` | `postToolUse` (matcher `bash\|powershell`) | `squad-notifications.instructions.md` | Best-effort, log-only: when a completed shell command looks like a notification send (`gh issue`, a webhook `curl`/`Invoke-RestMethod`), appends a line to `.copilot-tracking/squad/hooks-audit.log`. Never blocks — `postToolUse` runs after the call already completed. | This is explicitly the "defense-in-depth backstop, not a replacement" layer called out in ADR-0002's Consequences (see below) — the real enforcement (recognized-keyword-only approval, injection safety) is the GitHub Actions workflow at `skills/squad/github-approval-watcher.workflow.yml`, which runs server-side against real GitHub API data this hook cannot see. |
| `prompt-injection-note.sh`/`.ps1` | `userPromptSubmitted` | `squad-watch-mode.instructions.md` (untrusted trigger payload) | Log-only. | Confirmed from the hooks reference: a command-type `userPromptSubmitted` hook's output (`modifiedPrompt`) is **not honored** — only SDK programmatic hooks can rewrite or block on this event. So this hook has no enforcement capability at all; it is retained only to produce an audit trail entry, and is not a real backstop for the injection-safety rule. The actual Watch Mode injection-safety enforcement is, again, the GitHub Actions trigger workflow (`skills/squad/squad-watch.workflow.yml`), which reads the real event payload server-side. |

## Partial coverage, by design (ADR-0002 Consequences)

Per the plan's own P01-T03 scope decision and ADR-0002's Consequences section,
**`squad-notifications` and `squad-watch-mode` are a defense-in-depth backstop
here, not full coverage.** Their real enforcement already runs outside the
Copilot plugin hook surface entirely, as committed GitHub Actions workflows:

* `skills/squad/github-approval-watcher.workflow.yml` — the recognized-keyword-only
  approval rule and its authorization check.
* `skills/squad/squad-watch.workflow.yml` — the Watch Mode trigger, opt-in gate,
  and untrusted-payload handling.

A consumer who only installs this plugin and never copies those two workflows
into `.github/workflows/` has **no** enforcement for notifications/watch-mode
beyond the two log-only hooks above. Do not represent `hooks.json` as
providing full coverage for either file.

## Caller-identity limitation (applies across every `preToolUse` hook here)

Every `preToolUse` hook in this plugin can see the *tool being called* and the
raw *arguments passed to it*. None can see *which agent or subagent is
making the call*. That means the "only the Squad Scribe writes squad state"
half of the single-writer rule, and the "only `Squad Backlog Executor`
performs a tracker write" half of the Tracker-Write Gate, are not — and
cannot currently be — hook-enforced. Only their observable, path/pattern-based
half is enforced here. This is stated plainly rather than implied by a
passing-looking hook.

## Cloud agent scope

Per the same hooks reference, plugin-contributed `hooks.json` files are one of
several sources the **Copilot CLI** combines (policy, user, project, plugin).
**Copilot cloud agent only loads `.github/hooks/*.json` from the cloned
repository** — it does not load a plugin's own `hooks.json` at all. This is
exactly the gap P03-T06's hook-drop command exists to close: a consumer who
wants these same guards to run under the cloud agent must run the drop
command to materialize a copy under their own repository's
`.github/hooks/`.
