# FAQ

**Why scheduled tasks and not GitHub Actions or a daemon?**
Zero infrastructure and first-party. The trade is that runs bill the task owner's account and the feature is in research preview. If you need shared billing and resilience to one person's absence, the plugin runs unchanged under a self-hosted Agent SDK service or the Claude Code GitHub Action; only the orchestration layer changes.

**Can my teammates see or edit my scheduled tasks?**
No. Tasks belong to the account that created them ([docs](https://code.claude.com/docs/en/routines)). Document the owner of each task in your repo's `CLAUDE.md` or runbook.

**Pro/Max vs Team/Enterprise?**
The plugin works on all of them. Team/Enterprise additionally get Claude Tag in Slack, the hosted Code Review product, and org-level toggles. Nothing here depends on those.

**Why vendor the plugin instead of `enabledPlugins`?**
Cloud sessions don't install plugins a repository declares; they do load `.claude/skills`, `.claude/agents`, hooks and permission rules from the clone ([what carries over](https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup)). The installer puts the files where cloud sessions read them.

**Do I need MCP server config for Linear, Notion, Slack?**
Not for cloud sessions or scheduled tasks: the claude.ai connectors on your account are available and you choose which ones each task may use. For a local CLI session, connect the same services at [claude.ai/customize/connectors](https://claude.ai/customize/connectors) or add a token-based server to the repo's `.mcp.json` with `claude mcp add --scope project`.

**What happens if two runs pick the same ticket?**
The first adds `claude-in-progress`; the second sees it and moves on. If both start in the same minute, the branch-existence check in `/next-ticket` catches the second.

**The worker ran and did nothing.**
Expected when nothing has `claude-ready`. Check the issue has the label, is not completed, and has no `claude-blocked` or `claude-pr-open` label left over.

**A ticket is stuck in `claude-in-progress`.**
Open the worker task's run list. The run either hit a permission prompt waiting for you, hit usage limits, or failed. Clear the label and delete the branch to let the next run retry.

**Can the agent deploy to staging automatically?**
Make your CD do it on merge. Don't give the agent a deploy command; the deny rules exist so you never have to trust a prompt for this.

**Why does the reviewer never approve?**
An agent approval would satisfy a "1 required review" rule and remove the human gate. It only comments.
