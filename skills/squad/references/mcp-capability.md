---
name: squad-mcp-capability
description: "Capability-aware MCP routing for squad dispatched roles, with named fallbacks when an MCP is absent."
license: MIT
metadata:
  authors: "Peter-N91/hve-squad"
  spec_version: "1.0"
  last_updated: "2026-08-23"
---

# Squad MCP Capability

Ported from `squad-src/.github/instructions/squad/squad-mcp-capability.instructions.md`. This file tells the Squad Coordinator and every dispatched role how to choose between a Model Context Protocol (MCP) server and a non-MCP default for a given capability. Dispatched roles do not assume an MCP is present: they name the capability they need, check whether a preferred MCP is configured, and either use it or fall back to the named default without breaking the flow.

The plugin's own outbound MCP server registration (registering `hve-squad` itself as tools other hosts consume) is `.mcp.json` at the plugin root, generated from `skills/squad/mcp-server.template.json`. This file is the **inbound** capability map: which external MCP servers a dispatched role should reach for, and what to do when one is absent. The reference template for those external servers, `skills/squad/mcp.template.json`, remains a documentation-only snippet a consumer merges into their own `.vscode/mcp.json`; the plugin never reads or writes it.

## Capability Map

| Capability         | Preferred MCP                                | Non-MCP Fallback                                                                |
|--------------------|-----------------------------------------------|-----------------------------------------------------------------------------------|
| diagram-rendering  | A draw.io MCP server when one is configured  | Render Mermaid in chat; or author Mermaid in repository markdown                |
| ADO query          | `@azure-devops/mcp` (Microsoft official)     | `researcher` against the Azure DevOps REST API with a user-supplied PAT          |
| tracker-write      | `@azure-devops/mcp` (ADO), `github` MCP (GitHub), or the `jira` skill (Jira) | **None.** The role returns `blocked` — see *No Fallback for Writes* below |
| Azure-pricing      | `msftnadavbh/AzurePricingMCP` community server | `researcher` against the Azure Retail Prices REST API (`https://prices.azure.com/api/retail/prices`) |
| azure-resource     | `@azure/mcp` (official Azure MCP server)      | `researcher` against the Azure CLI (`az`) and the Azure Resource Graph / Resource Manager REST APIs using the user's `az login` context |
| architecture-docs  | `microsoft-docs` MCP when configured         | `researcher` against `learn.microsoft.com` via web fetch                        |
| code-context       | `context7` MCP when configured               | `researcher` against the published library documentation                        |
| github-issue       | `github` MCP (GitHub official) when configured | The `gh` CLI when authenticated; otherwise an in-chat ping (no remote approval) |

The `github-issue` capability backs the remote approval channel in [notifications-and-watch.md](notifications-and-watch.md). Its fallback chain is `github` MCP → `gh` CLI → in-chat.

The `azure-resource` capability backs the squad's Azure governance discovery, as-built inventory, and diagnose roles. All reads on this path are non-destructive.

### No Fallback for Writes

`tracker-write` is the one capability with no fallback, and the exception is deliberate. Every other row is a **read**, so a fallback that reaches the same data by another route is strictly better than blocking. A write is not: falling back would mean creating real work items in a real team's backlog through a path the user never configured. So when the ADO MCP is absent for `tracker=ado`, or the `jira` skill is unavailable for `tracker=jira`, the role returns `blocked` naming the missing capability — it does not fall back to the Azure DevOps REST API with a user-supplied PAT, even though the `ADO query` row permits exactly that for reads. This is also the one row `hooks.json`'s `dispatch-guards` script checks: a `task` dispatch that looks tracker-write-shaped and does not name `Squad Backlog Executor` is denied at the hook layer, not just by this convention. See `hooks/README.md`.

## Capability Hint Contract

1. Check whether the preferred MCP for the named capability is configured in the active workspace.
2. When configured and reachable, use it for the duration of the turn.
3. When absent or erroring, fall back to the named default without pausing the turn.
4. Record the choice in the role's response (`used: <preferred-mcp>` or `used: <fallback-name>`) so the Scribe can capture which path the turn took in `history/<agent>.md`.

## Graceful Degradation

Dispatched roles never block the squad on a missing MCP; they use the named fallback and continue, surfacing the choice in their response. When neither the preferred MCP nor the named fallback can satisfy the capability, the role escalates to the coordinator with a `blocked` status naming the capability and the failed paths.

## Out-of-Band Fallbacks

Two capabilities have no official MCP server at authoring time:

* **Draw.io** — install the `hediet.vscode-drawio` extension; it edits `.drawio`/`.dio`/`.drawio.svg`/`.drawio.png` natively and offline. No MCP entry required.
* **Python `diagrams` library** — run it through the `python-foundational` skill or directly in the terminal to render architecture diagrams as PNG/SVG via Graphviz. No MCP entry required.

## Consumer Override

The consumer owns every write to `.vscode/mcp.json`. The plugin ships only the reference template at `skills/squad/mcp.template.json` and never overwrites the consumer's MCP configuration. Consumers may adopt it verbatim, merge only selected entries, add servers the template does not include, or remove any server at any time — dispatched roles fall back per the capability map above.
