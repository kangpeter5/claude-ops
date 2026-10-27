# Security

## What this project does and does not control

claude-ops runs as **your** claude.ai account inside Claude Code cloud sessions. Everything it does on GitHub, Linear, Notion and Slack is attributed to you and limited by your permissions on those services. The plugin adds no credentials and stores none.

The deny rules and the guard hook reduce the chance that an agent runs a deploy, merge or force-push. They are not a substitute for:

- GitHub branch protection with required reviews and status checks
- A production deployment environment with required human approvers
- Least-privilege tokens on any connector you include in a scheduled task

Per the Claude Code docs, `permissions.deny` rules hold under every permission mode, while hooks are best-effort. Keep both.

## Reporting a vulnerability

Open a GitHub issue with the label `security`, or email the maintainer listed in `plugin/.claude-plugin/plugin.json`. Please do not include real tokens, repository contents, or customer data in the report.

## Supply chain

Pin the installer to a tag (`--ref v0.1.0`) and pin the marketplace plugin to a version. Review the diff of `plugin/` before updating a vendored copy; the installer prints the commit it installed into `.claude/claude-ops.lock`.
