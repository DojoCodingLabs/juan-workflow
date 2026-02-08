#!/usr/bin/env bash
# check-greptile.sh — Single instant check for Greptile review on a PR
# Usage: check-greptile.sh <PR_NUMBER> <OWNER/REPO>
#
# Does NOT sleep or poll. Checks once and returns immediately.
#
# Output (stdout):
#   - Review JSON if found (most recent Greptile review/comment)
#   - "NO_REVIEW" if Greptile hasn't reviewed yet
#   - "NO_GREPTILE" if bot is not configured on this repo
#   - "ERROR: <message>" on failures
#
# Requires: gh (authenticated), jq

set -o pipefail

PR_NUMBER="${1:?Usage: check-greptile.sh <PR_NUMBER> <OWNER/REPO>}"
OWNER_REPO="${2:?Usage: check-greptile.sh <PR_NUMBER> <OWNER/REPO>}"

# Verify tools
if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI not found"
  exit 1
fi
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found"
  exit 1
fi

# Check PR reviews for Greptile
REVIEWS=$(gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/reviews" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$REVIEWS" ]; then
  GREPTILE_REVIEW=$(echo "$REVIEWS" | jq -r '
    [.[] | select(
      (.user.login | ascii_downcase | contains("greptile"))
    )] | last
  ' 2>/dev/null)

  if [ "$GREPTILE_REVIEW" != "null" ] && [ -n "$GREPTILE_REVIEW" ]; then
    echo "$GREPTILE_REVIEW"
    exit 0
  fi
fi

# Check PR comments for Greptile (some bots comment instead of review)
COMMENTS=$(gh api "repos/${OWNER_REPO}/issues/${PR_NUMBER}/comments" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$COMMENTS" ]; then
  GREPTILE_COMMENT=$(echo "$COMMENTS" | jq -r '
    [.[] | select(
      (.user.login | ascii_downcase | contains("greptile"))
    )] | last
  ' 2>/dev/null)

  if [ "$GREPTILE_COMMENT" != "null" ] && [ -n "$GREPTILE_COMMENT" ]; then
    echo "$GREPTILE_COMMENT"
    exit 0
  fi
fi

# No Greptile review found — check if Greptile is even configured
# Look at the 3 most recent closed PRs for any Greptile activity
HAS_GREPTILE=$(gh pr list --state all --limit 3 --json number 2>/dev/null \
  | jq -r '.[].number' \
  | while read -r pr; do
      gh api "repos/${OWNER_REPO}/pulls/${pr}/reviews" --jq '.[].user.login' 2>/dev/null
      gh api "repos/${OWNER_REPO}/issues/${pr}/comments" --jq '.[].user.login' 2>/dev/null
    done \
  | grep -ci "greptile" 2>/dev/null)

if [ "${HAS_GREPTILE:-0}" -eq 0 ]; then
  echo "NO_GREPTILE"
else
  echo "NO_REVIEW"
fi

exit 0
