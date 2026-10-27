# Customizing

## CLAUDE.md is the configuration

The skills read the repository's `CLAUDE.md` for commands, the Linear team, sensitive paths, reviewers, release channel and changelog. Nothing in the plugin names your company. The template is [`templates/CLAUDE.md.example`](../templates/CLAUDE.md.example).

## Extra deny patterns

Add deny rules for your deploy CLI in `.claude/settings.json` under `permissions.deny`, and the same pattern in `env.CLAUDE_OPS_DENY_PATTERNS` so the hook's message explains the refusal.

## Changing the self-review cap or severity policy

Edit the vendored `.claude/skills/implement-ticket/SKILL.md` in your repo, or open a PR here if the change is generic. The installer overwrites the skills it owns on update, so repo-local edits need to be re-applied or kept in a separate skill.

## Adding a repo-specific skill

Put it under `.claude/skills/<name>/SKILL.md`. The installer never touches skills it didn't ship.

## Overriding a subagent

Copy `.claude/agents/reviewer.md` to a new name, change the tools or prompt, and reference the new name in your vendored skill. Prefer narrowing tools over widening them.

## Running on a second repository

Repeat the installer, fill in that repo's `CLAUDE.md`, create its three scheduled tasks. Each repo's worker is independent.

## Updating

```bash
curl -fsSL https://raw.githubusercontent.com/kangpeter5/claude-ops/main/scripts/install.sh | bash -s -- --ref v0.2.0
git diff .claude/
```

Review the diff, commit. `.claude/claude-ops.lock` records what is installed.
