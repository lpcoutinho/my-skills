#!/usr/bin/env bash
# Checks every skills/*/SKILL.md against the Agent Skills spec
# (https://agentskills.io/specification) so it loads in every harness:
#   - YAML frontmatter delimited by --- lines
#   - name: lowercase letters, digits and hyphens, at most 64 chars,
#     equal to the folder name
#   - description: present, at most 1024 chars
# Also checks that every entry in vendor.lock has a folder in skills/.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
errors=0
fail() { echo "FAIL $1: $2"; errors=$((errors + 1)); }

for skill_md in "$REPO"/skills/*/SKILL.md; do
  [ -e "$skill_md" ] || continue
  dir="$(basename "$(dirname "$skill_md")")"
  before=$errors

  if [ "$(head -n1 "$skill_md")" != "---" ]; then
    fail "$dir" "SKILL.md must start with a '---' frontmatter line"
    continue
  fi
  front="$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$skill_md")"

  name="$(printf '%s\n' "$front" | sed -n 's/^name:[[:space:]]*//p' | tr -d "\"'" | head -n1)"
  # description is either inline or a block scalar (| or >) indented below.
  description="$(printf '%s\n' "$front" | awk '
    /^description:/ { sub(/^description:[[:space:]]*[|>]?-?[[:space:]]*/, ""); text = $0; grab = 1; next }
    grab && /^[[:space:]]/ { sub(/^[[:space:]]+/, ""); text = text " " $0; next }
    grab { exit }
    END { print text }')"
  description="$(printf '%s' "$description" | sed 's/^[[:space:]]*//')"

  [ -n "$name" ] || fail "$dir" "missing name"
  [ "$name" = "$dir" ] || fail "$dir" "name '$name' does not match folder name"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "$dir" "name must be lowercase letters, digits and single hyphens"
  [ ${#name} -le 64 ] || fail "$dir" "name longer than 64 chars"
  [ -n "$description" ] || fail "$dir" "missing description"
  [ ${#description} -le 1024 ] || fail "$dir" "description has ${#description} chars (max 1024)"

  if [ $errors -eq $before ]; then echo "ok   $dir"; fi
done

if [ -f "$REPO/vendor.lock" ]; then
  while IFS=$'\t' read -r name _; do
    case "$name" in ''|'#'*) continue ;; esac
    [ -f "$REPO/skills/$name/SKILL.md" ] || fail "$name" "listed in vendor.lock but skills/$name/SKILL.md is missing"
  done < "$REPO/vendor.lock"
fi

if [ $errors -gt 0 ]; then
  echo "$errors problem(s) found"
  exit 1
fi
