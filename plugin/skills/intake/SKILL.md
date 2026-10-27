---
name: intake
description: Turn a Notion PRD and/or a Slack thread into Linear tickets in Triage, labeled agent-drafted, with a single "Decisions needed" issue for open questions. Human-triggered; never run on a schedule.
argument-hint: "<notion-url|-> <slack-thread-url|-> --team <KEY> [--project <name>]"
disable-model-invocation: true
allowed-tools: Agent, Read, Grep, Glob, mcp__Notion__*, mcp__Slack__*, mcp__Linear__*
effort: high
---

# /intake

Arguments: `$ARGUMENTS`

Parse them as: `<notion-url or ->`, `<slack-thread-url or ->`, `--team <LINEAR TEAM KEY>`, optional `--project <Linear project name>`. At least one source URL is required. If `--team` is missing, read it from the repository's `CLAUDE.md` under `## Linear` (`team: KEY`). If still missing, stop and ask.

## Why this skill exists

Drafting tickets is the step where a wrong output costs the most: a plausible ticket that misreads the PRD sends an engineer or an agent down the wrong path. So tickets land in **Triage** with the `agent-drafted` label and a human promotes them. This skill never sets any other state and never adds `claude-ready`.

## Steps

1. **Analyze.** Delegate to the `prd-analyst` subagent (named `delivery-loop:prd-analyst` when installed as a plugin) with the source URLs, the team key, and the instruction to return its YAML. Pass it nothing else; it must read the sources itself.
2. **Sanity check the YAML** before writing anything:
   - Every ticket has at least two acceptance criteria.
   - No ticket estimate is `l` without a `depends_on` or a split note. If one is, send it back to the analyst once with "split this".
   - `decisions_needed` entries are real gaps, not restatements of a requirement.
3. **Write.** Delegate to the `ticket-writer` subagent (`delivery-loop:ticket-writer` as a plugin) with the YAML, team key and project. It creates issues in Triage with `agent-drafted`, plus the single `Decisions needed` issue when needed.
4. **Report back to the source.** If a Slack thread URL was given, post one reply in that thread:

   ```
   Drafted <N> tickets in Linear from this thread and the PRD (Triage, label agent-drafted):
   • <KEY-1> <title>
   • <KEY-2> <title>
   Decisions needed before these can start: <KEY-D> (<count> questions)
   Promote a ticket and add the `claude-ready` label when it should be implemented.
   ```

   If only a Notion URL was given, add a comment on the Notion page with the same content.
5. **Summarize** to the user: the list of issue links, the decisions issue, and anything the analyst flagged as conflicting between PRD and thread.

## Never

- Never create tickets in any state other than Triage (or Backlog when the team has no Triage).
- Never add `claude-ready`, assign people, or set priorities. Those are human calls.
- Never paste the full PRD into a ticket. Link it.
