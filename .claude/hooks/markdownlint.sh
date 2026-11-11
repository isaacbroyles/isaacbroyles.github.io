#!/usr/bin/env bash
# PostToolUse hook: lint a Markdown file after Claude edits it.
# Exit 2 sends markdownlint's output back to Claude so it can fix the file.
set -euo pipefail

file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.md ]] || exit 0

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
rel="${file#"$root"/}"
case "$rel" in
  /*|vendor/*|node_modules/*|_site/*) exit 0 ;;
esac

cd "$root"
if ! output=$(npx --no-install markdownlint-cli2 "$rel" 2>&1); then
  echo "$output" >&2
  exit 2
fi
