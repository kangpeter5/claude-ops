# Guardrails

Three layers, in order of how much to trust them.

## 1. Your platform (trust this)

- **Branch protection**: required human review, required status checks, no direct pushes to the default branch. The agent's push goes through your connected GitHub identity, so a rule that identity can bypass doesn't block it. Don't give the identity bypass rights.
- **Deploy environment with required reviewers**: production deploys wait for a human. The agent never has a deploy credential, so there is nothing for it to misuse.
- **Connector scope**: each scheduled task lists the connectors it may use. Remove everything a task doesn't need; an included connector can write.

## 2. Claude Code permission rules (trust this)

`settings/recommended.json` adds `permissions.deny` rules for merge, force-push, release creation and common deploy CLIs, plus `Read` denies for `.env` and private keys. Per the [permissions docs](https://code.claude.com/docs/en/permissions), deny rules apply in every permission mode, including auto mode used by scheduled tasks and `bypassPermissions`. Add your own deploy CLI to the list.

## 3. The guard hook (defense in depth, not a gate)

`plugin/hooks/guard.sh` is a `PreToolUse` hook on `Bash`. It reads the command and returns a deny decision when it matches the built-in patterns or `CLAUDE_OPS_DENY_PATTERNS`. The [hooks docs](https://code.claude.com/docs/en/hooks) call hooks best-effort, so this is a second net under the deny rules, with a clearer message for the model.

Set extra patterns in `.claude/settings.json`:

```json
{ "env": { "CLAUDE_OPS_DENY_PATTERNS": "my-deploy-cli|flyctl deploy" } }
```

## Process guardrails

- **Triage for drafted tickets.** A human promotes and adds `claude-ready`. The agent never does.
- **One ticket per run, hourly.** Throughput is capped on purpose; human review is the bottleneck.
- **Self-review cap of three rounds.** Then `claude-blocked`, not a worse PR.
- **Never resolve threads, never approve, never request changes.** Reviewers keep those.
- **Every action leaves a comment** on the issue or the PR with the run link. If you can't find it in Linear or GitHub, it didn't happen.

## Kill switches

| Scope | How |
|---|---|
| One ticket | Remove `claude-ready` (and delete its `claude/` branch if already claimed) |
| One repo | Toggle the worker task off |
| Everything | Toggle all tasks off, or on Team/Enterprise an Owner disables scheduled tasks for the org |

## What this does not protect against

- A ticket that is wrong. The PR will faithfully implement it. Triage exists for this.
- Usage exhaustion. Runs bill the task owner. Watch the weekly limit.
- A connector with too much scope. Trim them per task.
