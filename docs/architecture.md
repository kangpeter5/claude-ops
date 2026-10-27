# Architecture

## Where things run and on whose usage

| Piece | Runs where | Billed to |
|---|---|---|
| `/intake` | A cloud or local session you start | You |
| worker, review, release tasks | Claude Code cloud sessions started by scheduled tasks | **The account that created the task** |
| Auto-fix on a PR | Cloud session | The person who enabled it |
| Review by humans, deploy approval | GitHub, your CD | nobody's Claude usage |

Scheduled tasks belong to an individual claude.ai account, are not shared with teammates, and count against that account's usage ([docs](https://code.claude.com/docs/en/routines)). This is the single biggest operational fact about this design: **the loop stops when its owner hits a usage limit or leaves**. Document who owns each task. If that is not acceptable, the plugin runs unchanged under a self-hosted orchestrator; see the FAQ.

## The state machine

Linear labels are the only state. Nothing is stored anywhere else.

| Label | Set by | Meaning |
|---|---|---|
| `agent-drafted` | `/intake` | Drafted from a PRD or thread. Sits in Triage until a human promotes it |
| `claude-ready` | a human | The agent may implement this |
| `claude-in-progress` | `/next-ticket` | Claimed; the claiming run is linked in a comment |
| `claude-blocked` | `/implement-ticket` | Needs a human decision; the comment says which |
| `claude-pr-open` | `/implement-ticket` | A PR is ready for human review |

Transitions only go forward and each one leaves a comment. Removing `claude-ready` stops work on that ticket; pausing the worker task stops everything.

## Why the pieces are shaped this way

**Intake is human-triggered.** Ticket creation is the step with the least verifiable output. A schedule that drafts from every new PRD fills Triage with plausible, wrong tickets. A person runs `/intake` when a PRD is ready.

**The worker is hourly and claims one ticket.** Scheduled tasks can't run more often than hourly, and one PR per hour per repo is already more than most teams can review. The claim label prevents two runs picking the same ticket.

**Self-review uses a separate subagent.** The implementer grading its own diff converges on "looks fine". The `reviewer` subagent starts with a fresh context, sees only the diff and the acceptance criteria, and returns JSON. The loop is capped at three rounds so a stubborn ticket ends in `claude-blocked` instead of burning usage.

**Review on PR-open is a first pass, not a gate.** Branch protection still requires a human approval. The agent's inline comments make that review faster.

**Deploy is never the agent's.** The agent has no deploy credentials, the deny rules block deploy CLIs, and the guard hook blocks them again. The real gate is your CD's production environment with a required reviewer.

## Vendored, not installed

Cloud sessions load `.claude/skills`, `.claude/agents`, hooks, permission rules and `.mcp.json` from the clone, but do not install plugins a repository declares ([what carries over](https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup)). So `scripts/install.sh` copies the plugin into `.claude/` and records the version in `.claude/claude-ops.lock`. The marketplace entry exists for local interactive use and for people who prefer `claude plugin install`.
