#!/usr/bin/env bash
# assign-reviewer.sh — Smart round-robin reviewer assignment
# Usage: assign-reviewer.sh <PATH_TO_CONFIG>
#
# Picks the next reviewer via round-robin, checks their pending review count
# via gh api, updates the index in config, and outputs:
#   REVIEWER:<login> PENDING:<count>
#
# Also outputs the full pool with pending counts for override support.
#
# Requires: jq, gh

set -o pipefail

CONFIG_PATH="${1:?Usage: assign-reviewer.sh <PATH_TO_CONFIG>}"

# Verify tools
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found. Install with: brew install jq"
  exit 1
fi
if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI not found"
  exit 1
fi

# Verify config exists
if [ ! -f "$CONFIG_PATH" ]; then
  echo "ERROR: Config not found at ${CONFIG_PATH}"
  exit 1
fi

# Read the reviewer pool and last index
POOL_SIZE=$(jq -r '.reviewers.pool | length' "$CONFIG_PATH" 2>/dev/null)
LAST_INDEX=$(jq -r '.reviewers.lastAssignedIndex' "$CONFIG_PATH" 2>/dev/null)
ORG=$(jq -r '.github.org // empty' "$CONFIG_PATH" 2>/dev/null)
REPO=$(jq -r '.github.repo // empty' "$CONFIG_PATH" 2>/dev/null)

if [ -z "$POOL_SIZE" ] || [ "$POOL_SIZE" -eq 0 ]; then
  echo "ERROR: No reviewers in pool. Run pattern-learner to populate."
  exit 1
fi

if [ -z "$LAST_INDEX" ] || [ "$LAST_INDEX" = "null" ]; then
  LAST_INDEX=-1
fi

# Function to get pending review count for a user
get_pending_reviews() {
  local login="$1"
  if [ -n "$ORG" ] && [ -n "$REPO" ]; then
    # Count open PRs where this user is requested as reviewer
    local count
    count=$(gh api "repos/${ORG}/${REPO}/pulls?state=open" --jq "
      [.[] | select(.requested_reviewers[]?.login == \"${login}\")] | length
    " 2>/dev/null)
    echo "${count:-0}"
  else
    echo "0"
  fi
}

# Calculate next index (round-robin)
NEXT_INDEX=$(( (LAST_INDEX + 1) % POOL_SIZE ))

# Get the reviewer at that index
REVIEWER=$(jq -r ".reviewers.pool[${NEXT_INDEX}]" "$CONFIG_PATH" 2>/dev/null)

if [ -z "$REVIEWER" ] || [ "$REVIEWER" = "null" ]; then
  echo "ERROR: Could not read reviewer at index ${NEXT_INDEX}"
  exit 1
fi

# Get pending review count for the chosen reviewer
PENDING=$(get_pending_reviews "$REVIEWER")

# Update the config with the new index
TEMP_FILE=$(mktemp)
jq ".reviewers.lastAssignedIndex = ${NEXT_INDEX}" "$CONFIG_PATH" > "$TEMP_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
  mv "$TEMP_FILE" "$CONFIG_PATH"
else
  rm -f "$TEMP_FILE"
fi

# Output chosen reviewer with pending count
echo "REVIEWER:${REVIEWER} PENDING:${PENDING}"

# Output full pool with pending counts (for override display)
echo "POOL_START"
for i in $(seq 0 $((POOL_SIZE - 1))); do
  MEMBER=$(jq -r ".reviewers.pool[${i}]" "$CONFIG_PATH" 2>/dev/null)
  MEMBER_PENDING=$(get_pending_reviews "$MEMBER")
  if [ "$i" -eq "$NEXT_INDEX" ]; then
    echo "* ${MEMBER} (${MEMBER_PENDING} pending) [SELECTED]"
  else
    echo "  ${MEMBER} (${MEMBER_PENDING} pending)"
  fi
done
echo "POOL_END"

exit 0
