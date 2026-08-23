# userPromptSubmitted — log-only injection-safety note.
# Source: squad-watch-mode.instructions.md (untrusted trigger payload rule).
# IMPORTANT (confirmed against the hooks reference): a command-type userPromptSubmitted
# hook's output (modifiedPrompt) is NOT honored - only SDK programmatic hooks can act on
# this event. This script has no enforcement capability; it exists only for an audit trail.
# See ../README.md.
$ErrorActionPreference = 'SilentlyContinue'

$input_raw = [Console]::In.ReadToEnd()
$logDir = '.copilot-tracking/squad'
$logFile = Join-Path $logDir 'hooks-audit.log'

if ($input_raw -match '(?i)ignore (all )?(previous|prior) instructions|skip the (gate|approval)|disregard the (gate|rule)') {
    if (Test-Path -LiteralPath $logDir -PathType Container) {
        $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        Add-Content -LiteralPath $logFile -Value "$ts prompt contained instruction-override-shaped language (log-only; this event cannot block or rewrite for command hooks)"
    }
}

Write-Output '{}'
