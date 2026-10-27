#!/usr/bin/env bash
# claude-ops PreToolUse guard for the Bash tool.
#
# Reads the hook payload on stdin, extracts tool_input.command, and denies
# anything that matches a deploy / force-push / merge pattern.
#
# This hook is a second line of defense. The first line is permissions.deny in
# .claude/settings.json, which holds under every permission mode. Hooks are
# best-effort per https://code.claude.com/docs/en/hooks, so never rely on this
# alone.
#
# Extend the pattern list without editing this file:
#   CLAUDE_OPS_DENY_PATTERNS="my-deploy-cli|flyctl deploy"   (ERE, pipe-separated)
set -euo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

default_patterns='git push[^|;&]* (--force|-f)( |$)|git push[^|;&]* \+|gh pr merge|gh workflow run|gh release create|gh run rerun|kubectl (apply|delete|rollout|scale)|helm (install|upgrade|rollback|uninstall)|terraform (apply|destroy)|pulumi (up|destroy)|aws (ecs|lambda|cloudformation|s3) [a-z-]*(deploy|update|delete|create-stack)|gcloud (run|app|functions) deploy|az (webapp|functionapp|containerapp) (up|deploy)|vercel( --prod| deploy| --prod)|netlify deploy|flyctl deploy|fly deploy|heroku (releases:rollback|container:release)|cap[istrano]* (production|staging) deploy|serverless deploy|sls deploy|docker (push|compose up -d)|git push[^|;&]* origin (main|master|production|release)( |$)'

patterns="$default_patterns"
if [ -n "${CLAUDE_OPS_DENY_PATTERNS:-}" ]; then
  patterns="$patterns|${CLAUDE_OPS_DENY_PATTERNS}"
fi

if printf '%s' "$cmd" | grep -Eq "$patterns"; then
  reason="claude-ops guard: this command looks like a deploy, force-push, merge or release action. Those are reserved for humans. Open or update the PR and stop; a person will approve the deploy. See docs/guardrails.md."
  jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

exit 0
