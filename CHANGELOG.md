# Changelog

## 0.1.0 (unreleased)

Initial engine.

- Skills: `intake`, `next-ticket`, `implement-ticket` (with self-review loop), `address-review`, `release`
- Subagents: `prd-analyst`, `ticket-writer`, `reviewer`, `pr-responder`, each with a tool allowlist
- `PreToolUse` guard hook for deploy, merge and force-push commands
- `settings/recommended.json` deny rules
- `scripts/install.sh` to vendor the plugin into a repo's `.claude/` for cloud sessions
- Scheduled-task prompts for worker, review and release
- Docs
