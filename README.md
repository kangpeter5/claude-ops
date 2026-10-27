# claude-ops

A Claude Code plugin and playbook that works Linear tickets end to end on **Claude Code on the web scheduled tasks**, with no CI orchestration to maintain:

1. **Intake**: a Notion PRD plus a Slack thread become Linear tickets in Triage. A human promotes them.
2. **Implement**: an hourly task claims the next `claude-ready` ticket, implements it, opens a draft PR, and **reviews its own work with a fresh-context reviewer until clean** (max 3 rounds). Then it marks the PR ready.
3. **Review**: a task fires on PR open and leaves inline findings. A human still approves.
4. **Follow-up**: review comments and CI failures get fixed and replied to. Threads are never resolved by the agent.
5. **Release**: on merge, a deploy checklist, a release note, Linear → Done, and a Slack post. **Deploy stays human.**

```
Notion PRD + Slack thread ──/intake──▶ Linear: Triage, agent-drafted
                                            │ human adds claude-ready
   worker task (hourly) ◀───────────────────┘
   claim → branch → implement → tests → draft PR
   self-review loop: reviewer subagent → pr-responder → repeat (≤3)
   clean → gh pr ready → Linear: claude-pr-open
                     │
   review task (PR opened) → inline comments     human review required
                     │
   review comments → Auto-fix or /address-review
                     │
   merge → your CD → production needs a human approver
   release task (PR merged) → checklist, release note, Linear Done, Slack
```

## What you add to a repository

Three things, about 40 lines of your own writing:

| File | What it holds |
|---|---|
| `CLAUDE.md` | Build, test and lint commands, the Linear team key, sensitive paths, reviewers |
| `.claude/` (vendored by the installer) | Skills, subagents, the deploy-guard hook, deny rules |
| Three scheduled tasks on claude.ai | worker (hourly), review (PR opened), release (PR merged) |

Plus branch protection and a production environment with a required reviewer, which you probably already have.

## Install

From the root of the target repository:

```bash
curl -fsSL https://raw.githubusercontent.com/kangpeter5/claude-ops/main/scripts/install.sh | bash -s -- --ref v0.1.0
```

Then edit `CLAUDE.md`, commit `.claude/` and `CLAUDE.md`, and create the three scheduled tasks from [`routines/`](routines/). The whole path is in [docs/getting-started.md](docs/getting-started.md).

For local interactive use you can also install it as a plugin:

```bash
claude plugin marketplace add kangpeter5/claude-ops
claude plugin install delivery-loop@claude-ops
```

Why both? Cloud sessions (and scheduled tasks) load a repo's `.claude/skills`, `.claude/agents`, hooks and permission rules from the clone, but [do not install plugins a repo declares](https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup). The installer vendors the plugin so it works in both places.

## Skills

| Skill | Does |
|---|---|
| `/intake <notion> <slack> --team KEY` | PRD + thread → Linear tickets in Triage with `agent-drafted`, plus one "Decisions needed" issue |
| `/next-ticket KEY` | Claim the oldest `claude-ready` issue, hand off to `/implement-ticket` |
| `/implement-ticket KEY` | Branch, implement, test, draft PR, self-review loop, `gh pr ready`, `claude-pr-open` |
| `/address-review [pr]` | Fix unresolved review threads and failing checks, reply per thread |
| `/release <pr>` | Deploy checklist, release note, Linear Done, Slack post |

Subagents: `prd-analyst` (read-only), `ticket-writer` (Linear only), `reviewer` (read-only, fresh context), `pr-responder` (edit + git). Each has a tool allowlist. See [docs/skills.md](docs/skills.md).

## Guardrails

- `permissions.deny` rules for merge, force-push, deploy CLIs. [These hold under every permission mode](https://code.claude.com/docs/en/permissions).
- A `PreToolUse` hook that denies the same commands plus anything in `CLAUDE_OPS_DENY_PATTERNS`.
- Linear labels as the state machine; removing `claude-ready` is the per-ticket kill switch, pausing the task is the global one.
- Every agent action leaves a Linear or PR comment with a link to the run.

Details and the reasoning in [docs/guardrails.md](docs/guardrails.md).

## Docs

- [Getting started](docs/getting-started.md): the 15-minute path
- [Architecture](docs/architecture.md): what runs where, on whose usage, and the label state machine
- [Scheduled tasks](docs/scheduled-tasks.md): each task's trigger, prompt, connectors and limits
- [Skills](docs/skills.md), [Guardrails](docs/guardrails.md), [Customizing](docs/customizing.md), [FAQ](docs/faq.md)

## Requirements

- Claude Pro, Max, Team or Enterprise (scheduled tasks and cloud sessions)
- GitHub with the [Claude GitHub App](https://github.com/apps/claude) installed on the target repo
- Linear, and optionally Notion and Slack, connected as [claude.ai connectors](https://claude.ai/customize/connectors)

## License

MIT. See [LICENSE](LICENSE).
