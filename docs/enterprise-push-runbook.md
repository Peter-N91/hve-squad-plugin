# Enterprise push runbook: force-installing `hve-squad` org-wide

This is for GitHub Copilot enterprise admins who want every developer in
their enterprise to receive the `hve-squad` plugin automatically, without
each person running `copilot plugin install` themselves. It uses GitHub
Copilot's enterprise-managed settings (`managed-settings.json`), the same
mechanism enterprises use to force-install any other Copilot plugin.

## How it works

An enterprise admin adds an entry under `enabledPlugins` in the
enterprise's `copilot/managed-settings.json` (server-managed, in a
`.github-private` repository — the default and recommended deployment
method) or in an MDM-/file-based `managed-settings.json` for local-client-only
enforcement. `enabledPlugins` and `extraKnownMarketplaces` work
additively: a marketplace this plugin's repo is not one of Copilot's
built-in defaults, so the enterprise settings must also register it via
`extraKnownMarketplaces` before referencing it in `enabledPlugins`. Once
committed and pushed to the governance repo's default branch, every
supported client (Copilot CLI, VS Code, JetBrains, the GitHub Copilot app,
Copilot cloud agent) picks up the policy on next sign-in or within about an
hour, and installs the plugin for each user automatically — the user only
needs read access to `Peter-N91/hve-squad-plugin` (public, MIT), so no
extra licensing or access grant is required.

## Example `managed-settings.json` entry

```json
{
  "extraKnownMarketplaces": {
    "hve-squad-plugin": {
      "source": {
        "source": "github",
        "repo": "Peter-N91/hve-squad-plugin",
        "ref": "master"
      }
    }
  },
  "enabledPlugins": {
    "hve-squad@hve-squad-plugin": true
  }
}
```

The `enabledPlugins` key is `PLUGIN-NAME@MARKETPLACE-NAME` — `hve-squad` is
the plugin name from this repo's `.github/plugin/plugin.json`, and
`hve-squad-plugin` is the marketplace name from
`.github/plugin/marketplace.json`'s top-level `name` field. Both must match
exactly, or the reference resolves to nothing.

## Notes for admins

* Setting `{ "overridable": true }` on either key in the enterprise default
  lets individual enterprise teams add further marketplaces/plugins on top
  of this baseline via `copilot/team-mappings.json` and per-team files under
  `copilot/teams/` — see GitHub's [Configuring enterprise-managed
  settings](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/configure-enterprise-managed-settings)
  guide for the override syntax.
* A plugin or marketplace pinned this way cannot be disabled or repointed
  by an individual user locally — the managed value always wins for that
  entry, and the CLI's `/plugins` dashboard marks it `Managed`.
* This runbook only documents the mechanism. Pushing this entry into any
  specific organization's `managed-settings.json` is that organization's own
  action, not something this repository or its maintainers perform on an
  adopter's behalf.
