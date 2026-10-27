#!/usr/bin/env bash
# claude-ops installer: vendor the plugin into a target repository's .claude/ directory.
#
# Why vendor instead of installing the plugin?
#   Claude Code cloud sessions (and therefore scheduled tasks) load a repo's
#   .claude/skills, .claude/agents, hooks and permission rules from the clone,
#   but they do NOT install plugins declared under enabledPlugins /
#   extraKnownMarketplaces. See:
#   https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup
#
# Usage (run from the root of the target repository):
#   curl -fsSL https://raw.githubusercontent.com/kangpeter5/claude-ops/main/scripts/install.sh | bash -s -- [--ref v0.1.0]
# or, with a local clone of claude-ops:
#   /path/to/claude-ops/scripts/install.sh [--ref v0.1.0] [--source /path/to/claude-ops]
#
# Re-run to update. The script only writes under .claude/ and prints the
# settings.json snippet to merge when a settings file already exists.
set -euo pipefail

REPO_URL="https://github.com/kangpeter5/claude-ops.git"
REF="main"
SOURCE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --source) SOURCE="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ ! -d .git ]; then
  echo "install.sh: run this from the root of the target git repository" >&2
  exit 1
fi

tmp=""
if [ -z "$SOURCE" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 --branch "$REF" "$REPO_URL" "$tmp/claude-ops"
  SOURCE="$tmp/claude-ops"
fi
PLUGIN="$SOURCE/plugin"
[ -d "$PLUGIN/skills" ] || { echo "install.sh: $PLUGIN/skills not found" >&2; exit 1; }

version="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$PLUGIN/.claude-plugin/plugin.json" | head -1)"
sha="$(git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null || echo unknown)"

mkdir -p .claude/skills .claude/agents .claude/hooks/claude-ops

# Skills and agents: replace only the ones claude-ops owns, keep the repo's own.
for d in "$PLUGIN"/skills/*/; do
  name="$(basename "$d")"
  rm -rf ".claude/skills/$name"
  cp -R "$d" ".claude/skills/$name"
done
for f in "$PLUGIN"/agents/*.md; do
  cp "$f" ".claude/agents/$(basename "$f")"
done
cp "$PLUGIN/hooks/guard.sh" .claude/hooks/claude-ops/guard.sh
chmod +x .claude/hooks/claude-ops/guard.sh

cat > .claude/claude-ops.lock <<LOCK
# Managed by claude-ops/scripts/install.sh. Re-run the installer to update.
version=$version
ref=$REF
commit=$sha
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOCK

if [ ! -f CLAUDE.md ]; then
  cp "$SOURCE/templates/CLAUDE.md.example" CLAUDE.md
  echo "Created CLAUDE.md from the template. Fill in the commands and the Linear team key."
fi

if [ ! -f .claude/settings.json ]; then
  cp "$SOURCE/settings/recommended.json" .claude/settings.json
  echo "Created .claude/settings.json with the recommended deny rules and guard hook."
else
  echo
  echo "A .claude/settings.json already exists. Merge these keys into it (deny rules merge as lists):"
  echo "----- settings/recommended.json -----"
  cat "$SOURCE/settings/recommended.json"
  echo "-------------------------------------"
fi

echo
echo "claude-ops $version ($sha) installed into .claude/"
echo "  skills:  $(ls "$PLUGIN"/skills | tr '\n' ' ')"
echo "  agents:  $(ls "$PLUGIN"/agents | sed 's/\.md//' | tr '\n' ' ')"
echo "  hook:    .claude/hooks/claude-ops/guard.sh"
echo
echo "Next: edit CLAUDE.md, commit .claude/ and CLAUDE.md, then create the scheduled tasks (docs/scheduled-tasks.md)."
