#!/usr/bin/env bash
# wait-greptile.sh — Polls a GitHub PR for Greptile's review
# Usage: wait-greptile.sh <PR_NUMBER> <OWNER/REPO>
#
# Behavior:
#   1. Initial wait of 6 minutes
#   2. Check for Greptile review via gh api
#   3. If not found, wait 2 more minutes and retry
#   4. Max total wait: 15 minutes
#
# Output (stdout):
#   - Review body if found (JSON with score + comments)
#   - "TIMEOUT" if max wait exceeded
#   - "NO_GREPTILE" if bot is not configured (no reviews from any bot after timeout)
#   - "ERROR: <message>" on failures
#
# Requires: gh (authenticated), jq

set -o pipefail

PR_NUMBER="${1:?Usage: wait-greptile.sh <PR_NUMBER> <OWNER/REPO>}"
OWNER_REPO="${2:?Usage: wait-greptile.sh <PR_NUMBER> <OWNER/REPO>}"

INITIAL_WAIT=360    # 6 minutes
RETRY_WAIT=120      # 2 minutes
MAX_TOTAL_WAIT=900  # 15 minutes
ELAPSED=0

# Verify gh is available
if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI not found. Install from https://cli.github.com"
  exit 1
fi

# Verify jq is available
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found. Install with: brew install jq"
  exit 1
fi

# Verify the PR exists
if ! gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}" --jq '.number' &>/dev/null; then
  echo "ERROR: PR #${PR_NUMBER} not found in ${OWNER_REPO}"
  exit 1
fi

# Function to check for Greptile review
check_greptile_review() {
  # Get all reviews on the PR
  local reviews
  reviews=$(gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/reviews" 2>/dev/null)
  
  if [ $? -ne 0 ] || [ -z "$reviews" ]; then
    return 1
  fi

  # Look for reviews from Greptile (case-insensitive match on username)
  local greptile_review
  greptile_review=$(echo "$reviews" | jq -r '
    [.[] | select(
      (.user.login | ascii_downcase | contains("greptile")) or
      (.user.type == "Bot" and (.user.login | ascii_downcase | contains("greptile")))
    )] | last
  ' 2>/dev/null)

  if [ "$greptile_review" = "null" ] || [ -z "$greptile_review" ]; then
    # Also check PR comments (some bots comment instead of review)
    local comments
    comments=$(gh api "repos/${OWNER_REPO}/issues/${PR_NUMBER}/comments" 2>/dev/null)
    
    greptile_review=$(echo "$comments" | jq -r '
      [.[] | select(
        (.user.login | ascii_downcase | contains("greptile")) or
        (.user.type == "Bot" and (.user.login | ascii_downcase | contains("greptile")))
      )] | last
    ' 2>/dev/null)
  fi

  if [ "$greptile_review" != "null" ] && [ -n "$greptile_review" ]; then
    echo "$greptile_review"
    return 0
  fi

  return 1
}

# ── Main loop ──────────────────────────────────────────────

# Initial wait
sleep "$INITIAL_WAIT"
ELAPSED=$((ELAPSED + INITIAL_WAIT))

while [ "$ELAPSED" -lt "$MAX_TOTAL_WAIT" ]; do
  REVIEW=$(check_greptile_review)
  
  if [ $? -eq 0 ] && [ -n "$REVIEW" ]; then
    # Found Greptile review — output it
    echo "$REVIEW"
    exit 0
  fi

  # Not found yet — wait and retry
  REMAINING=$((MAX_TOTAL_WAIT - ELAPSED))
  
  if [ "$REMAINING" -le 0 ]; then
    break
  fi

  # Wait the retry interval (or remaining time, whichever is smaller)
  WAIT_TIME=$((RETRY_WAIT < REMAINING ? RETRY_WAIT : REMAINING))
  sleep "$WAIT_TIME"
  ELAPSED=$((ELAPSED + WAIT_TIME))
done

# Timed out — determine if Greptile is even configured
# Check if ANY bot has ever reviewed PRs in this repo
HAS_BOT_REVIEWS=$(gh pr list --state all --limit 5 --json number \
  | jq -r '.[].number' \
  | while read -r pr; do
      gh api "repos/${OWNER_REPO}/pulls/${pr}/reviews" --jq '.[].user.login' 2>/dev/null
    done \
  | grep -ci "greptile" 2>/dev/null)

if [ "${HAS_BOT_REVIEWS:-0}" -eq 0 ]; then
  echo "NO_GREPTILE"
else
  echo "TIMEOUT"
fi

exit 0
